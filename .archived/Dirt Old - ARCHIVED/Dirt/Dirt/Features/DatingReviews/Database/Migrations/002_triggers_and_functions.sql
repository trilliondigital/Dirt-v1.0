-- Migration 002: Triggers and Functions for Dating Reviews Platform
-- Created: 2025-09-18
-- Description: Adds database triggers and functions for automatic updates

-- Function for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updating timestamps
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_reviews_updated_at ON reviews;
CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_comments_updated_at ON comments;
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_votes_updated_at ON user_votes;
CREATE TRIGGER update_user_votes_updated_at BEFORE UPDATE ON user_votes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_reports_updated_at ON reports;
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function for updating comment counts
CREATE OR REPLACE FUNCTION update_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Increment comment count
        IF NEW.content_type = 'post' THEN
            UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.content_id;
        ELSIF NEW.content_type = 'review' THEN
            UPDATE reviews SET comment_count = comment_count + 1 WHERE id = NEW.content_id;
        ELSIF NEW.content_type = 'comment' AND NEW.parent_id IS NOT NULL THEN
            UPDATE comments SET reply_count = reply_count + 1 WHERE id = NEW.parent_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Decrement comment count
        IF OLD.content_type = 'post' THEN
            UPDATE posts SET comment_count = GREATEST(0, comment_count - 1) WHERE id = OLD.content_id;
        ELSIF OLD.content_type = 'review' THEN
            UPDATE reviews SET comment_count = GREATEST(0, comment_count - 1) WHERE id = OLD.content_id;
        ELSIF OLD.content_type = 'comment' AND OLD.parent_id IS NOT NULL THEN
            UPDATE comments SET reply_count = GREATEST(0, reply_count - 1) WHERE id = OLD.parent_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Create trigger for comment count updates
DROP TRIGGER IF EXISTS update_comment_count_trigger ON comments;
CREATE TRIGGER update_comment_count_trigger
    AFTER INSERT OR DELETE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_comment_count();

-- Function for updating vote counts
CREATE OR REPLACE FUNCTION update_vote_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Update vote counts based on new vote
        IF NEW.content_type = 'post' THEN
            UPDATE posts SET 
                upvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = NEW.content_id AND content_type = 'post' AND vote_type = 'upvote'),
                downvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = NEW.content_id AND content_type = 'post' AND vote_type = 'downvote')
            WHERE id = NEW.content_id;
        ELSIF NEW.content_type = 'review' THEN
            UPDATE reviews SET 
                upvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = NEW.content_id AND content_type = 'review' AND vote_type = 'upvote'),
                downvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = NEW.content_id AND content_type = 'review' AND vote_type = 'downvote')
            WHERE id = NEW.content_id;
        ELSIF NEW.content_type = 'comment' THEN
            UPDATE comments SET 
                upvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = NEW.content_id AND content_type = 'comment' AND vote_type = 'upvote'),
                downvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = NEW.content_id AND content_type = 'comment' AND vote_type = 'downvote')
            WHERE id = NEW.content_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Update vote counts after deletion
        IF OLD.content_type = 'post' THEN
            UPDATE posts SET 
                upvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = OLD.content_id AND content_type = 'post' AND vote_type = 'upvote'),
                downvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = OLD.content_id AND content_type = 'post' AND vote_type = 'downvote')
            WHERE id = OLD.content_id;
        ELSIF OLD.content_type = 'review' THEN
            UPDATE reviews SET 
                upvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = OLD.content_id AND content_type = 'review' AND vote_type = 'upvote'),
                downvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = OLD.content_id AND content_type = 'review' AND vote_type = 'downvote')
            WHERE id = OLD.content_id;
        ELSIF OLD.content_type = 'comment' THEN
            UPDATE comments SET 
                upvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = OLD.content_id AND content_type = 'comment' AND vote_type = 'upvote'),
                downvotes = (SELECT COUNT(*) FROM user_votes WHERE content_id = OLD.content_id AND content_type = 'comment' AND vote_type = 'downvote')
            WHERE id = OLD.content_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Create trigger for vote count updates
DROP TRIGGER IF EXISTS update_vote_counts_trigger ON user_votes;
CREATE TRIGGER update_vote_counts_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_votes
    FOR EACH ROW EXECUTE FUNCTION update_vote_counts();

-- Function for updating user reputation based on votes
CREATE OR REPLACE FUNCTION update_user_reputation()
RETURNS TRIGGER AS $$
DECLARE
    author_id_var UUID;
    reputation_change INTEGER := 0;
BEGIN
    -- Get the author ID based on content type
    IF NEW.content_type = 'post' THEN
        SELECT author_id INTO author_id_var FROM posts WHERE id = NEW.content_id;
    ELSIF NEW.content_type = 'review' THEN
        SELECT author_id INTO author_id_var FROM reviews WHERE id = NEW.content_id;
    ELSIF NEW.content_type = 'comment' THEN
        SELECT author_id INTO author_id_var FROM comments WHERE id = NEW.content_id;
    END IF;

    -- Don't update reputation for self-votes
    IF author_id_var = NEW.user_id THEN
        RETURN NEW;
    END IF;

    -- Calculate reputation change
    IF TG_OP = 'INSERT' THEN
        IF NEW.vote_type = 'upvote' THEN
            reputation_change := 1;
        ELSIF NEW.vote_type = 'downvote' THEN
            reputation_change := -1;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle vote changes
        IF OLD.vote_type = 'upvote' AND NEW.vote_type = 'downvote' THEN
            reputation_change := -2;
        ELSIF OLD.vote_type = 'downvote' AND NEW.vote_type = 'upvote' THEN
            reputation_change := 2;
        ELSIF OLD.vote_type = 'upvote' AND NEW.vote_type = 'none' THEN
            reputation_change := -1;
        ELSIF OLD.vote_type = 'downvote' AND NEW.vote_type = 'none' THEN
            reputation_change := 1;
        ELSIF OLD.vote_type = 'none' AND NEW.vote_type = 'upvote' THEN
            reputation_change := 1;
        ELSIF OLD.vote_type = 'none' AND NEW.vote_type = 'downvote' THEN
            reputation_change := -1;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.vote_type = 'upvote' THEN
            reputation_change := -1;
        ELSIF OLD.vote_type = 'downvote' THEN
            reputation_change := 1;
        END IF;
    END IF;

    -- Update user reputation
    IF reputation_change != 0 AND author_id_var IS NOT NULL THEN
        UPDATE users 
        SET reputation = GREATEST(0, reputation + reputation_change)
        WHERE id = author_id_var;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ language 'plpgsql';

-- Create trigger for reputation updates
DROP TRIGGER IF EXISTS update_user_reputation_trigger ON user_votes;
CREATE TRIGGER update_user_reputation_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_votes
    FOR EACH ROW EXECUTE FUNCTION update_user_reputation();