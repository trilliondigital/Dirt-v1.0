-- Dating Reviews Platform Database Schema
-- This schema supports the core data models for the dating review platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    anonymous_username VARCHAR(50) UNIQUE NOT NULL,
    phone_number_hash VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reputation INTEGER DEFAULT 0 CHECK (reputation >= 0),
    is_verified BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notification_preferences JSONB DEFAULT '{
        "repliesEnabled": true,
        "upvotesEnabled": true,
        "milestonesEnabled": true,
        "announcementsEnabled": true,
        "recommendationsEnabled": false
    }'::jsonb,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reviews table
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    profile_screenshots TEXT[] NOT NULL,
    ratings JSONB NOT NULL CHECK (
        (ratings->>'photos')::int BETWEEN 1 AND 5 AND
        (ratings->>'bio')::int BETWEEN 1 AND 5 AND
        (ratings->>'conversation')::int BETWEEN 1 AND 5 AND
        (ratings->>'overall')::int BETWEEN 1 AND 5
    ),
    content TEXT NOT NULL CHECK (length(content) > 0),
    tags TEXT[] DEFAULT '{}',
    dating_app VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    upvotes INTEGER DEFAULT 0 CHECK (upvotes >= 0),
    downvotes INTEGER DEFAULT 0 CHECK (downvotes >= 0),
    comment_count INTEGER DEFAULT 0 CHECK (comment_count >= 0),
    is_moderated BOOLEAN DEFAULT FALSE,
    moderation_status VARCHAR(20) DEFAULT 'pending' CHECK (
        moderation_status IN ('pending', 'approved', 'rejected', 'flagged', 'under_review')
    ),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Posts table
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL CHECK (length(title) > 0),
    content TEXT NOT NULL CHECK (length(content) > 0 AND length(content) <= 10000),
    category VARCHAR(50) NOT NULL CHECK (
        category IN ('Advice', 'Experience', 'Question', 'Strategy', 'Success Story', 'Rant', 'General Discussion')
    ),
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    upvotes INTEGER DEFAULT 0 CHECK (upvotes >= 0),
    downvotes INTEGER DEFAULT 0 CHECK (downvotes >= 0),
    comment_count INTEGER DEFAULT 0 CHECK (comment_count >= 0),
    is_moderated BOOLEAN DEFAULT FALSE,
    moderation_status VARCHAR(20) DEFAULT 'pending' CHECK (
        moderation_status IN ('pending', 'approved', 'rejected', 'flagged', 'under_review')
    ),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comments table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content_id UUID NOT NULL,
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('post', 'review', 'comment')),
    content TEXT NOT NULL CHECK (length(content) > 0 AND length(content) <= 2000),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    upvotes INTEGER DEFAULT 0 CHECK (upvotes >= 0),
    downvotes INTEGER DEFAULT 0 CHECK (downvotes >= 0),
    reply_count INTEGER DEFAULT 0 CHECK (reply_count >= 0),
    is_moderated BOOLEAN DEFAULT FALSE,
    moderation_status VARCHAR(20) DEFAULT 'pending' CHECK (
        moderation_status IN ('pending', 'approved', 'rejected', 'flagged', 'under_review')
    ),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User votes table (for tracking upvotes/downvotes)
CREATE TABLE user_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_id UUID NOT NULL,
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('post', 'review', 'comment')),
    vote_type VARCHAR(10) NOT NULL CHECK (vote_type IN ('upvote', 'downvote', 'none')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, content_id, content_type)
);

-- Reports table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_id UUID NOT NULL,
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('post', 'review', 'comment')),
    reason VARCHAR(50) NOT NULL CHECK (
        reason IN ('Harassment', 'Spam', 'Personal Information', 'Inappropriate Content', 
                  'Misinformation', 'Violence or Threats', 'Hate Speech', 'Other')
    ),
    additional_context TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending' CHECK (
        status IN ('pending', 'reviewed', 'action_taken', 'dismissed')
    ),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_users_anonymous_username ON users(anonymous_username);
CREATE INDEX idx_users_phone_hash ON users(phone_number_hash);
CREATE INDEX idx_users_reputation ON users(reputation DESC);
CREATE INDEX idx_users_last_active ON users(last_active_at DESC);

CREATE INDEX idx_reviews_author ON reviews(author_id);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);
CREATE INDEX idx_reviews_moderation_status ON reviews(moderation_status);
CREATE INDEX idx_reviews_dating_app ON reviews(dating_app);
CREATE INDEX idx_reviews_tags ON reviews USING GIN(tags);
CREATE INDEX idx_reviews_net_score ON reviews((upvotes - downvotes) DESC);

CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_category ON posts(category);
CREATE INDEX idx_posts_moderation_status ON posts(moderation_status);
CREATE INDEX idx_posts_tags ON posts USING GIN(tags);
CREATE INDEX idx_posts_net_score ON posts((upvotes - downvotes) DESC);

CREATE INDEX idx_comments_author ON comments(author_id);
CREATE INDEX idx_comments_content ON comments(content_id, content_type);
CREATE INDEX idx_comments_parent ON comments(parent_id);
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);
CREATE INDEX idx_comments_moderation_status ON comments(moderation_status);

CREATE INDEX idx_user_votes_user_content ON user_votes(user_id, content_id, content_type);
CREATE INDEX idx_user_votes_content ON user_votes(content_id, content_type);

CREATE INDEX idx_reports_content ON reports(content_id, content_type);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);

-- Triggers for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_votes_updated_at BEFORE UPDATE ON user_votes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Functions for updating comment counts
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
            UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.content_id;
        ELSIF OLD.content_type = 'review' THEN
            UPDATE reviews SET comment_count = comment_count - 1 WHERE id = OLD.content_id;
        ELSIF OLD.content_type = 'comment' AND OLD.parent_id IS NOT NULL THEN
            UPDATE comments SET reply_count = reply_count - 1 WHERE id = OLD.parent_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

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

CREATE TRIGGER update_vote_counts_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_votes
    FOR EACH ROW EXECUTE FUNCTION update_vote_counts();