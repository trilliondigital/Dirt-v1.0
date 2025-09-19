# Dirt - Dating Feedback Community

A privacy-first, male-focused dating feedback app built with SwiftUI and Supabase.

## Overview

Dirt is a safe space for men to share honest dating experiences, get advice, and support each other. The app prioritizes user privacy with anonymous posting by default while fostering a supportive community environment.

## Features

### Core Features
- **Anonymous Posting**: Users can post completely anonymously by default
- **Red/Green Flag System**: Posts are categorized by sentiment (positive, negative, neutral)
- **Category-Based Organization**: Posts organized by advice, experience, questions, strategy, success stories, rants, and general discussion
- **Engagement System**: Upvote/downvote system with reputation tracking
- **Search & Discovery**: Full-text search with trending topics and popular content
- **Notifications**: Real-time notifications for interactions and milestones

### Privacy & Safety
- **Privacy First**: No personal information required, anonymous by default
- **Content Moderation**: Community reporting system with moderation tools
- **Safe Environment**: Guidelines and enforcement to maintain respectful discourse

## Architecture

### Project Structure
```
Dirt New/
├── DirtApp.swift                    # App entry point
├── ContentView.swift                # Root view controller
├── Core/                           # Core app infrastructure
│   ├── AppState.swift              # Global app state management
│   ├── Models/                     # Core data models
│   └── Services/                   # Core services (Auth, Supabase)
├── Features/                       # Feature modules
│   ├── Onboarding/                 # User onboarding flow
│   ├── Main/                       # Main tab navigation
│   ├── Feed/                       # Post feed and interactions
│   ├── Search/                     # Search and discovery
│   ├── CreatePost/                 # Post creation
│   ├── Notifications/              # Notification management
│   └── Profile/                    # User profile and settings
└── README.md                       # This file
```

### Key Components

#### Core Models
- **User**: User profile with privacy settings and reputation
- **Post**: Content posts with sentiment, category, and engagement metrics
- **Comment**: User comments on posts
- **DirtNotification**: In-app notifications

#### Services
- **AuthenticationService**: Handles user authentication (Apple Sign In, Anonymous)
- **SupabaseManager**: Database operations and real-time updates

#### Features
- **Feed**: Main content feed with filtering and sorting
- **Search**: Content discovery with trending topics
- **Create Post**: Post creation with guidelines and validation
- **Notifications**: Real-time notification management
- **Profile**: User profile, settings, and account management

## Technical Stack

- **Frontend**: SwiftUI (iOS 16+)
- **Backend**: Supabase (PostgreSQL, Auth, Real-time)
- **Authentication**: Apple Sign In, Anonymous authentication
- **State Management**: Combine + ObservableObject
- **Architecture**: MVVM with service layer

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ deployment target
- Supabase account and project

### Installation
1. Clone the repository
2. Open `DirtApp.swift` in Xcode
3. Configure Supabase credentials in `SupabaseManager.swift`
4. Build and run the project

### Configuration
1. **Supabase Setup**:
   - Create a new Supabase project
   - Set up authentication providers (Apple Sign In)
   - Configure database schema (see backend documentation)
   - Update `supabaseURL` and `supabaseAnonKey` in `SupabaseManager.swift`

2. **Apple Sign In**:
   - Enable Apple Sign In capability in Xcode
   - Configure Apple Developer account settings

## Development Guidelines

### Code Style
- Follow Swift naming conventions
- Use SwiftUI best practices
- Implement proper error handling
- Add comprehensive comments for complex logic

### Testing
- Write unit tests for ViewModels
- Test core business logic
- Validate user flows

### Privacy & Security
- Never store PII without explicit consent
- Implement proper data encryption
- Follow Apple's privacy guidelines
- Regular security audits

## Contributing

1. Follow the established architecture patterns
2. Maintain code quality and documentation
3. Test thoroughly before submitting
4. Respect user privacy in all implementations

## License

This project is proprietary. All rights reserved.

## Support

For technical support or questions, please contact the development team.