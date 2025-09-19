# Dating Reviews Platform - Core Structure

This directory contains the core data models, database schema, and services for the dating reviews platform feature within the Dirt app.

## Directory Structure

```
DatingReviews/
├── Models/
│   ├── User.swift              # User model with reputation and preferences
│   ├── Review.swift            # Dating profile review model with ratings
│   ├── Post.swift              # Discussion post model with categories
│   └── Comment.swift           # Comment model with threading support
├── Database/
│   ├── Schema.sql              # Complete database schema
│   └── Migrations/
│       ├── 001_initial_schema.sql      # Initial table creation
│       └── 002_triggers_and_functions.sql  # Database triggers and functions
├── Services/
│   ├── ModelValidationService.swift    # Validation logic for all models
│   └── SerializationService.swift      # JSON serialization/deserialization
└── README.md                   # This file
```

## Core Models

### User Model
- Anonymous username system for privacy
- Reputation tracking based on community feedback
- Notification preferences
- Account status (verified, banned, etc.)

### Review Model
- Multi-category rating system (photos, bio, conversation, overall)
- Support for multiple profile screenshots
- Tag system for categorization
- Moderation status tracking

### Post Model
- Discussion posts with categories (Advice, Experience, Question, etc.)
- Tag system for discoverability
- Engagement metrics (upvotes, downvotes, comments)

### Comment Model
- Threaded comment system with parent-child relationships
- Support for comments on both posts and reviews
- Vote tracking and moderation status

## Database Schema

The database schema includes:
- All core tables with proper constraints and indexes
- Automatic triggers for updating vote counts and comment counts
- User reputation calculation based on community feedback
- Comprehensive moderation system support

## Services

### ModelValidationService
- Validates all model data before persistence
- Content moderation checks for inappropriate content
- Business logic validation (username restrictions, content length, etc.)

### SerializationService
- JSON encoding/decoding for all models
- Database serialization helpers
- API serialization support
- Batch operations for multiple objects

## Key Features

1. **Privacy-First Design**: Anonymous usernames, phone number hashing
2. **Community Moderation**: Reputation system, content flagging, moderation queue
3. **Rich Content Support**: Multi-category ratings, threaded discussions, image uploads
4. **Scalable Architecture**: Proper indexing, efficient queries, batch operations
5. **Data Integrity**: Comprehensive validation, database constraints, error handling

## Requirements Addressed

This implementation addresses the following requirements from the specification:

- **Requirement 1.6**: Anonymous profile system with generated usernames
- **Requirement 2.1**: Reputation tracking and community-driven moderation
- **Requirement 3.2**: Multi-category rating system for dating profiles
- **Requirement 4.1**: Discussion post creation with categories and tags

## Next Steps

After this core structure is in place, the following features can be built:

1. Authentication and onboarding system
2. Content creation and management interfaces
3. Search and discovery features
4. Notification system
5. Moderation tools and interfaces
6. API endpoints and data persistence layers

## Usage

All models include validation methods and can be serialized to/from JSON:

```swift
// Create and validate a user
let user = User(anonymousUsername: "user123", phoneNumberHash: "hashed_phone")
try ModelValidationService.shared.validateUser(user)

// Serialize to JSON
let json = try user.toJSON()

// Deserialize from JSON
let deserializedUser = try User.fromJSON(json)
```

The database schema can be applied using the migration files in order:
1. `001_initial_schema.sql` - Creates all tables and indexes
2. `002_triggers_and_functions.sql` - Adds triggers and functions for automatic updates