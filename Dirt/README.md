# Dirt - Dating Community App

A SwiftUI-based iOS app for sharing dating experiences, getting advice, and helping others navigate their dating journey.

## Features

- **Anonymous Posting**: Share experiences without revealing your identity
- **Community Feed**: Browse posts from other users with filtering and sorting
- **Categories**: Organize posts by advice, experiences, questions, strategies, success stories, and rants
- **Sentiment Tracking**: Mark posts as green flags, red flags, or neutral
- **User Authentication**: Apple Sign In and anonymous authentication
- **Real-time Notifications**: Stay updated on community interactions

## Technical Stack

- **Frontend**: SwiftUI (iOS 16+)
- **Backend**: Supabase (PostgreSQL, Auth, Real-time)
- **Authentication**: Apple Sign In, Anonymous authentication
- **State Management**: Combine + ObservableObject
- **Architecture**: MVVM with service layer

## Project Structure

```
Dirt/
├── Core/
│   ├── Models/          # Data models (User, Post, Comment)
│   ├── Services/        # Business logic services
│   └── AppState.swift   # Global app state management
├── Features/
│   ├── Feed/           # Main content feed
│   ├── CreatePost/     # Post creation
│   ├── Notifications/  # Notification management
│   ├── Profile/        # User profile and settings
│   └── Reviews/        # App/venue reviews (coming soon)
├── Views/              # Shared UI components
└── Assets.xcassets/    # App icons and images
```

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ deployment target
- Supabase account and project (for production)

### Installation
1. Clone the repository
2. Open `Dirt.xcodeproj` in Xcode
3. Configure Supabase credentials in `SupabaseManager.swift` (optional for development)
4. Build and run the project

### Configuration
1. **Supabase Setup** (for production):
   - Create a new Supabase project
   - Set up authentication providers (Apple Sign In)
   - Configure database schema
   - Update `supabaseURL` and `supabaseAnonKey` in `SupabaseManager.swift`

2. **Apple Sign In**:
   - Enable Apple Sign In capability in Xcode
   - Configure Apple Developer account settings

## Development

The app currently uses mock data for development. All core features are implemented with proper UI and state management, ready to be connected to a real backend.

### Key Components

- **AppState**: Manages global app state, navigation, and tab management
- **AuthenticationService**: Handles user authentication flows
- **SupabaseManager**: Database operations and API calls (currently mocked)
- **NotificationManager**: Manages in-app notifications

### Architecture

The app follows MVVM architecture with:
- **Models**: Data structures and business logic
- **Views**: SwiftUI UI components
- **ViewModels**: Reactive state management with ObservableObject
- **Services**: Business logic and external API integration

## Contributing

1. Follow Swift naming conventions and SwiftUI best practices
2. Maintain proper separation of concerns
3. Add comprehensive comments for complex logic
4. Test thoroughly before submitting changes

## Privacy & Security

- Anonymous posting by default
- No PII storage without explicit consent
- Proper data encryption for sensitive information
- Follows Apple's privacy guidelines

## License

This project is proprietary. All rights reserved.