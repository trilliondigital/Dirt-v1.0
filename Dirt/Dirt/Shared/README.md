# Shared Components

This directory contains cross-feature shared components, utilities, and models that are used throughout the Dirt iOS app.

## Overview

The shared components provide reusable functionality that spans multiple features, ensuring consistency and reducing code duplication across the app.

## Directory Structure

```
Shared/
├── Utilities/       # Cross-feature utility functions and services
└── README.md        # This file
```

## Utilities

The `Utilities/` directory contains shared utility functions and services:

### Core Utilities
- **`Validation.swift`** - Form validation and input sanitization
- **`FormValidation.swift`** - Enhanced form validation with Material Glass integration
- **`PasswordValidator.swift`** - Password strength validation and requirements
- **`Retry.swift`** - Exponential backoff retry mechanism for network operations

### Media and Content
- **`ImageProcessing.swift`** - Image processing, EXIF stripping, and blur effects
- **`AvatarProvider.swift`** - Avatar generation and management utilities
- **`LocationManager.swift`** - Location services and privacy-compliant location handling

### User Experience
- **`EnhancedHapticFeedback.swift`** - Advanced haptic feedback patterns
- **`ReportService.swift`** - Content reporting and moderation utilities
- **`ModerationQueue.swift`** - Content moderation queue management

## Usage Patterns

### Validation

```swift
import Validation

// Basic validation
let isValid = Validation.isValidEmail("user@example.com")
let isSecure = PasswordValidator.isSecure("password123")

// Form validation with Material Glass
struct LoginForm: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        GlassCard {
            VStack {
                TextField("Email", text: $email)
                    .textFieldStyle(GlassTextFieldStyle())
                    .validation(Validation.email)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(GlassTextFieldStyle())
                    .validation(PasswordValidator.requirements)
            }
        }
    }
}
```

### Image Processing

```swift
import ImageProcessing

// Process uploaded image
let processedImage = try await ImageProcessing.process(
    image: originalImage,
    stripEXIF: true,
    applyBlur: true,
    maxSize: CGSize(width: 1024, height: 1024)
)
```

### Haptic Feedback

```swift
import EnhancedHapticFeedback

// Provide contextual haptic feedback
EnhancedHapticFeedback.success() // For successful actions
EnhancedHapticFeedback.warning() // For warnings
EnhancedHapticFeedback.error() // For errors
EnhancedHapticFeedback.selection() // For UI selections
```

### Retry Mechanism

```swift
import Retry

// Retry network operations with exponential backoff
let result = try await Retry.withExponentialBackoff(
    maxAttempts: 3,
    baseDelay: 1.0
) {
    try await networkOperation()
}
```

## Design Principles

### Reusability

Shared components are designed for maximum reusability:
- Generic implementations that work across features
- Configurable behavior through parameters
- Minimal dependencies on specific feature logic

### Consistency

Utilities ensure consistent behavior across the app:
- Standardized validation rules
- Consistent error handling patterns
- Uniform user experience patterns

### Performance

Shared utilities are optimized for performance:
- Efficient algorithms and data structures
- Minimal memory allocation
- Proper resource cleanup

### Accessibility

All shared components include accessibility support:
- VoiceOver compatibility
- Dynamic Type support
- Reduced motion respect
- High contrast support

## Testing

Shared utilities include comprehensive test coverage:
- Unit tests for all utility functions
- Performance tests for critical operations
- Accessibility tests for UI-related utilities
- Integration tests for cross-feature functionality

### Test Organization

```
DirtTests/
├── ValidationTests.swift
├── ImageProcessingTests.swift
├── RetryTests.swift
├── HapticFeedbackTests.swift
└── [other utility tests]
```

## Security and Privacy

### Data Protection

Shared utilities handle sensitive data securely:
- EXIF data stripping for privacy
- Secure validation that prevents injection attacks
- Location data anonymization
- Proper cleanup of sensitive data in memory

### Privacy Compliance

Utilities respect user privacy preferences:
- Location services require explicit permission
- Image processing preserves user privacy
- Analytics utilities allow opt-out
- Data minimization principles

## Performance Monitoring

### Metrics

Shared utilities include performance monitoring:
- Image processing time tracking
- Validation performance metrics
- Network retry success rates
- Haptic feedback responsiveness

### Optimization

Continuous optimization of shared utilities:
- Algorithm improvements
- Memory usage optimization
- Battery usage minimization
- Thermal impact reduction

## Contributing

When adding new shared utilities:

1. **Assess Reusability**: Ensure the utility will be used by multiple features
2. **Follow Patterns**: Use established patterns from existing utilities
3. **Include Tests**: Add comprehensive unit and integration tests
4. **Document Usage**: Provide clear usage examples and API documentation
5. **Consider Performance**: Optimize for the expected usage patterns
6. **Accessibility**: Include accessibility support from the start

### Code Review Checklist

- [ ] Utility is truly cross-feature (used by 2+ features)
- [ ] Includes comprehensive unit tests
- [ ] Follows established error handling patterns
- [ ] Includes accessibility support
- [ ] Performance optimized for expected usage
- [ ] Properly documented with usage examples
- [ ] Security reviewed for sensitive operations

## Future Enhancements

### Planned Utilities

- **CacheManager**: Unified caching strategy across features
- **BiometricUtils**: Biometric authentication utilities
- **NetworkUtils**: Enhanced network utilities with offline support
- **AnalyticsUtils**: Privacy-compliant analytics utilities

### Architecture Improvements

- Dependency injection for utility configuration
- Plugin architecture for extensible utilities
- Performance monitoring and alerting
- Automated testing for utility compatibility

## Migration Guide

When moving utilities from feature-specific to shared:

1. **Extract Common Logic**: Identify truly reusable components
2. **Generalize Interface**: Remove feature-specific dependencies
3. **Update Imports**: Update all references to use shared utilities
4. **Test Integration**: Ensure all features work with shared utilities
5. **Update Documentation**: Document the migration and new usage patterns