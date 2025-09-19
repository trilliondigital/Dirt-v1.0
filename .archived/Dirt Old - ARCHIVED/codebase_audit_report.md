# Dirt iOS Codebase Audit Report

## Executive Summary

This audit analyzes the current Dirt iOS codebase to identify active, inactive, and duplicate code as part of the architectural refactoring initiative. The analysis reveals a well-organized feature-based structure with some areas requiring cleanup and consolidation.

## Project Structure Overview

```
Dirt/
├── Dirt/                           # Main iOS app target
│   ├── App/                        # App lifecycle and configuration
│   ├── Features/                   # Feature modules (12 features)
│   ├── Services/                   # Business logic services (20 services)
│   ├── UI/                         # Design system and components
│   ├── Utilities/                  # Helper utilities (11 utilities)
│   ├── Models/                     # Data models
│   └── Resources/                  # Assets and localizations
├── DirtTests/                      # Unit tests
├── DirtUITests/                    # UI tests
└── Dirt.xcodeproj/                 # Xcode project configuration
```

## File Inventory Analysis

### Active Files (High Confidence)

#### Core App Structure
- `App/AppDelegate/DirtApp.swift` - **ACTIVE** - Main app entry point, actively used
- `Features/*/Views/*.swift` - **ACTIVE** - All feature view files appear to be in use

#### Services Layer (20 files)
**Core Services (Active)**
- `SupabaseManager.swift` - **ACTIVE** - Database connection, referenced in DirtApp.swift
- `PostService.swift` - **ACTIVE** - Core post functionality
- `ErrorPresenter.swift` - **ACTIVE** - Error handling, referenced in SearchView.swift
- `ThemeService.swift` - **ACTIVE** - Theme management
- `AnalyticsService.swift` - **ACTIVE** - Analytics tracking
- `BiometricAuthService.swift` - **ACTIVE** - Authentication
- `DeepLinkService.swift` - **ACTIVE** - Deep linking
- `ModerationService.swift` - **ACTIVE** - Content moderation
- `InterestsService.swift` - **ACTIVE** - User interests
- `TutorialService.swift` - **ACTIVE** - User onboarding
- `AlertsService.swift` - **ACTIVE** - Alert management
- `ConfirmationCodeService.swift` - **ACTIVE** - Auth codes
- `PostSubmissionService.swift` - **ACTIVE** - Post creation
- `PerformanceService.swift` - **ACTIVE** - Performance monitoring
- `ErrorHandlingService.swift` - **ACTIVE** - Error management
- `MentionsService.swift` - **ACTIVE** - User mentions

**Potentially Duplicate Services (Requires Investigation)**
- `MediaService.swift` vs `EnhancedMediaService.swift` - **DUPLICATE CANDIDATES**
- `SearchService.swift` vs `EnhancedSearchService.swift` - **DUPLICATE CANDIDATES**

#### Utilities Layer (11 files)
**Core Utilities (Active)**
- `Validation.swift` - **ACTIVE** - Form validation
- `FormValidation.swift` - **ACTIVE** - Enhanced form validation
- `PasswordValidator.swift` - **ACTIVE** - Password validation
- `LocationManager.swift` - **ACTIVE** - Location services
- `ImageProcessing.swift` - **ACTIVE** - Image manipulation
- `AvatarProvider.swift` - **ACTIVE** - Avatar generation
- `ModerationQueue.swift` - **ACTIVE** - Content moderation
- `ReportService.swift` - **ACTIVE** - User reporting
- `Retry.swift` - **ACTIVE** - Network retry logic

**Potentially Duplicate Utilities**
- `HapticFeedback.swift` vs `EnhancedHapticFeedback.swift` - **DUPLICATE CANDIDATES**

#### UI Layer
- `UI/Design/DesignTokens.swift` - **ACTIVE** - Design system tokens
- `UI/Design/CardStyles.swift` - **ACTIVE** - Card styling
- `UI/Components/ToastView.swift` - **ACTIVE** - Toast notifications
- `UI/Components/InfiniteScrollView.swift` - **ACTIVE** - Infinite scrolling

#### Models
- `Models/ControlledTags.swift` - **ACTIVE** - Tag management
- `Models/Todo.swift` - **POTENTIALLY INACTIVE** - May be development artifact

### Duplicate Code Analysis

#### 1. MediaService vs EnhancedMediaService

**MediaService.swift** (Simple)
- Basic media processing via Supabase edge function
- Single method: `processMedia(at:)`
- 15 lines of code
- **Status: BASIC IMPLEMENTATION**

**EnhancedMediaService.swift** (Comprehensive)
- Full media management system with UI components
- Image compression, upload progress, multiple file types
- SwiftUI components for media picking
- 500+ lines of code
- **Status: FULL-FEATURED IMPLEMENTATION**

**Recommendation: CONSOLIDATE** - Keep EnhancedMediaService, archive MediaService

#### 2. SearchService vs EnhancedSearchService

**SearchService.swift** (Basic)
- Simple search with caching
- Basic search results model
- Backend integration with fallback
- ~100 lines of code
- **Status: BASIC IMPLEMENTATION**

**EnhancedSearchService.swift** (Comprehensive)
- Advanced search with filters, scopes, sorting
- Search suggestions, saved searches
- Complete SwiftUI search interface
- 600+ lines of code
- **Status: FULL-FEATURED IMPLEMENTATION**

**Current Usage**: SearchView.swift uses `SearchService.shared.search()`
**Recommendation: CONSOLIDATE** - Migrate to EnhancedSearchService, update SearchView

#### 3. HapticFeedback vs EnhancedHapticFeedback

**HapticFeedback.swift** (Simple)
- Basic haptic feedback enum
- Simple impact and notification methods
- 25 lines of code
- **Status: BASIC IMPLEMENTATION**

**EnhancedHapticFeedback.swift** (Comprehensive)
- Full haptic system with SwiftUI integration
- User preferences, test interface
- Context-aware haptic patterns
- 400+ lines of code
- **Status: FULL-FEATURED IMPLEMENTATION**

**Current Usage**: SearchView.swift uses `HapticFeedback.impact()` and `HapticFeedback.notification()`
**Recommendation: CONSOLIDATE** - Migrate to EnhancedHapticFeedback, update references

### Feature Analysis

#### Active Features (12 features)
All feature directories contain active SwiftUI views:

1. **CreatePost** - Post creation functionality
2. **Feed** - Main content feed
3. **Home** - Home screen and navigation
4. **Invite** - User invitation system
5. **Lookup** - User lookup functionality
6. **Moderation** - Content moderation tools
7. **Notifications** - Push notifications
8. **Onboarding** - User onboarding flow
9. **Profile** - User profiles
10. **Search** - Content search (uses SearchService)
11. **Settings** - App settings
12. **Topics** - Topic management

**Status: ALL ACTIVE** - No inactive features identified

### Unused/Inactive Files

#### Potentially Inactive
- `Models/Todo.swift` - May be development artifact, requires verification
- User data files in `.xcodeproj/xcuserdata/` - Development artifacts, can be ignored

#### Test Files (Active)
- `DirtTests/` - 4 test files, all appear active
- `DirtUITests/` - 2 test files, all appear active

## Dependencies Analysis

### External Dependencies
- **Supabase** - Database and backend services
- **SwiftUI** - UI framework
- **Combine** - Reactive programming
- **PhotosUI** - Photo picker integration
- **AVFoundation** - Media processing

### Internal Dependencies
- Services layer is well-isolated
- Features depend on shared services through singleton pattern
- UI components are properly modularized

## Build Performance Impact

### Current Issues
1. **Duplicate Services** - Multiple implementations increase build time
2. **Large Files** - EnhancedMediaService (500+ lines) could be split
3. **Circular Dependencies** - None identified (good)

### Optimization Opportunities
1. Consolidate duplicate services
2. Split large service files into focused modules
3. Implement proper dependency injection

## Recommendations

### Immediate Actions (High Priority)

1. **Consolidate Duplicate Services**
   - Merge MediaService → EnhancedMediaService
   - Merge SearchService → EnhancedSearchService  
   - Merge HapticFeedback → EnhancedHapticFeedback
   - Update all references in SearchView.swift

2. **Archive Unused Files**
   - Move `Models/Todo.swift` to archive if confirmed unused
   - Clean up user-specific Xcode files

3. **Update Service References**
   - Update SearchView.swift to use consolidated services
   - Ensure all haptic feedback calls use new API

### Medium Priority

1. **Service Organization**
   - Move core services to `Core/Services/`
   - Keep feature-specific services in feature directories
   - Implement service container pattern

2. **File Structure Cleanup**
   - Organize imports consistently
   - Remove unused import statements
   - Standardize file headers

### Low Priority

1. **Documentation**
   - Add README files to major directories
   - Document service responsibilities
   - Create architectural decision records

## Risk Assessment

### Low Risk
- Consolidating unused duplicate services
- Moving files to new directory structure
- Updating import statements

### Medium Risk
- Changing service APIs (requires thorough testing)
- Modifying core app structure

### High Risk
- None identified - codebase is well-structured

## Conclusion

The Dirt iOS codebase is well-organized with a clear feature-based architecture. The main issues are:

1. **3 sets of duplicate services** that should be consolidated
2. **Minor cleanup** of potentially unused files
3. **Service reference updates** needed in SearchView.swift

The codebase is in good shape for the planned Material Glass refactoring, with no major architectural issues or significant technical debt identified.

## Next Steps

1. Execute service consolidation plan
2. Update service references in active code
3. Archive unused files
4. Proceed with Core architecture foundation (Task 2)

---

**Audit completed:** $(date)
**Files analyzed:** ~50 Swift files
**Duplicate services identified:** 3 pairs
**Inactive files identified:** 1 potential (Todo.swift)
**Overall codebase health:** Good