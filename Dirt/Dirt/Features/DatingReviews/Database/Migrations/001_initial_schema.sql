-- Migration 001: Initial Schema for Dating Reviews Platform
-- Created: 2025-09-18
-- Description: Creates the initial database schema for the dating reviews platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
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
CREATE TABLE IF NOT EXISTS reviews (
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
CREATE TABLE IF NOT EXISTS posts (
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
CREATE TABLE IF NOT EXISTS comments (
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

-- User votes table
CREATE TABLE IF NOT EXISTS user_votes (
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
CREATE TABLE IF NOT EXISTS reports (
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_anonymous_username ON users(anonymous_username);
CREATE INDEX IF NOT EXISTS idx_users_phone_hash ON users(phone_number_hash);
CREATE INDEX IF NOT EXISTS idx_users_reputation ON users(reputation DESC);
CREATE INDEX IF NOT EXISTS idx_users_last_active ON users(last_active_at DESC);

CREATE INDEX IF NOT EXISTS idx_reviews_author ON reviews(author_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_moderation_status ON reviews(moderation_status);
CREATE INDEX IF NOT EXISTS idx_reviews_dating_app ON reviews(dating_app);
CREATE INDEX IF NOT EXISTS idx_reviews_tags ON reviews USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_reviews_net_score ON reviews((upvotes - downvotes) DESC);

CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_category ON posts(category);
CREATE INDEX IF NOT EXISTS idx_posts_moderation_status ON posts(moderation_status);
CREATE INDEX IF NOT EXISTS idx_posts_tags ON posts USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_posts_net_score ON posts((upvotes - downvotes) DESC);

CREATE INDEX IF NOT EXISTS idx_comments_author ON comments(author_id);
CREATE INDEX IF NOT EXISTS idx_comments_content ON comments(content_id, content_type);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_moderation_status ON comments(moderation_status);

CREATE INDEX IF NOT EXISTS idx_user_votes_user_content ON user_votes(user_id, content_id, content_type);
CREATE INDEX IF NOT EXISTS idx_user_votes_content ON user_votes(content_id, content_type);

CREATE INDEX IF NOT EXISTS idx_reports_content ON reports(content_id, content_type);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at DESC);