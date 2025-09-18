# Dirt v1.0

Dirt is a male-focused, privacy-first dating feedback app (SwiftUI + Supabase). This repo contains the iOS app, backend infrastructure (Supabase), and documentation.

## Layout
- `Dirt/` — iOS app project (SwiftUI)
- `backend/` — Supabase (Postgres, Auth, Storage, Edge Functions)
- `docs/` — Whitepaper, reference assets, and docs index
- `.backups/` — Timestamped backups (code-safety only; excluded from VCS)

## iOS App Architecture

The iOS app follows a clean, modular architecture with clear separation of concerns:

### Directory Structure
```
Dirt/Dirt/
├── App/                    # App lifecycle and configuration
├── Core/                   # Foundational systems
│   ├── Design/            # Material Glass design system
│   ├── Navigation/        # Navigation coordination
│   └── Services/          # Core infrastructure services
├── Features/              # Feature modules
│   ├── Feed/              # Main content feed
│   ├── Search/            # Global search functionality
│   ├── CreatePost/        # Post creation
│   └── [other features]/
├── Shared/                # Cross-feature shared components
│   ├── Models/            # Common data models
│   └── Utilities/         # Shared utility functions
└── Resources/             # Assets and localizations
```

### Key Architectural Principles
- **Feature Boundaries**: Clear module boundaries with minimal inter-feature dependencies
- **Service Container**: Centralized dependency injection for all services
- **Material Glass Design**: iOS 18+ Material Glass design system throughout
- **Accessibility First**: WCAG 2.1 AA compliance across all components

### Implemented UX (v1)
- Feed/Post actions: Helpful (👍), Save, Share, Report with reason sheet and soft-hide
- Search: Saved searches and typeahead suggestions; quick filters (Recent/Popular/Nearby/Trending)
- Create Post: required Red/Green flag, controlled tags, 500-char limit; optional photo auto-blurred with EXIF strip stub
- Notifications: Activity and Keyword Alerts tabs
- Profile: Anonymous shell with Saved and Liked placeholders

### Material Glass Design System
- **Core System**: `Dirt/Dirt/Core/Design/MaterialDesignSystem.swift`
- **Glass Components**: `Dirt/Dirt/Core/Design/GlassComponents.swift`
- **Design Tokens**: `Dirt/Dirt/Core/Design/DesignTokens.swift`
- **Motion System**: `Dirt/Dirt/Core/Design/MotionSystem.swift`
- **Accessibility**: `Dirt/Dirt/Core/Design/AccessibilitySystem.swift`

The design system provides Material Glass effects with proper accessibility support and dark mode compatibility.

### Utilities & Moderation
- Validation + ReportReason: `Dirt/Dirt/Utilities/Validation.swift`
- ReportService (stub): `Dirt/Dirt/Utilities/ReportService.swift` (centralizes report submission)
- ModerationQueue (stub): `Dirt/Dirt/Utilities/ModerationQueue.swift` (auto-hide threshold)
- Image processing: `Dirt/Dirt/Utilities/ImageProcessing.swift` (blur + EXIF strip stub)

## Backend
See `backend/README.md` for setup, env, migrations, RLS, and security. Key Edge Functions used by the app:

- `posts-create` — validated post creation with RLS/auth
- `moderation-submit` / `moderation-queue` / `moderation-update` — report pipeline and queue actions
- `saved-searches-list` / `saved-searches-save` / `saved-searches-delete`
- `interests-save` — onboarding interests persistence
- `search-global` — global search across posts/tags/sentiments
- `mentions-process` — processes @mentions post-create (scaffolded)
- `media-process` — computes content hash and handles EXIF stripping (scaffolded)

## Docs
- `docs/whitepaper_dirt.md` — MVP whitepaper
- `docs/Tea/` — Reference screenshots (not shipped)

## Security & Privacy
- Minimal PII, anonymous-first
- Strict RLS in Postgres
- Signed URLs for media, EXIF stripped on device
 - In-app reporting with local soft-hide and auto-hide threshold (see `SECURITY.md`)

### Error Handling
- Centralized user-facing copy via `ErrorPresenter.message(for:)`.
- Errors are surfaced through `ToastCenter` with consistent accessibility labels.

### Analytics
- `AnalyticsService` logs major events:
  - Post creation (includes time-to-first-post from first app launch)
  - Report submit success/failure
  - Moderation queue load and status updates
  - Helpful toggles in Feed/Post Detail

### Tests
- Unit tests live in `Dirt/DirtTests/`:
  - `RetryTests` — exponential backoff behavior
  - `MentionsServiceTests` — mention extraction
  - `SearchServiceTests` — LRU cache hit behavior

### Performance
- `SearchService` includes a small in-memory LRU cache keyed by query+tags+sort to reduce duplicate backend calls.

## Getting Started
1) iOS: open `Dirt/Dirt.xcodeproj` and build for iPhone
2) Backend: follow `backend/README.md`
3) Deploy Edge Functions: from `backend/functions/`, deploy required functions (`posts-create`, moderation/search/saved-searches, `mentions-process`, `media-process`).
4) Configure secrets: set Supabase URL and anon key via build settings or xcconfig. Do not commit actual secrets.

## Architecture Documentation

Comprehensive architecture documentation is available in the `docs/` directory:

- **[Coding Standards](docs/CODING_STANDARDS.md)** - Development guidelines and best practices
- **[Architecture Decisions](docs/architecture/)** - ADRs documenting major design choices
- **[Dependency Diagrams](docs/architecture/DEPENDENCY_DIAGRAMS.md)** - Visual module relationships

### Component Documentation
- **[Core Systems](Dirt/Dirt/Core/README.md)** - Service container and core infrastructure
- **[Design System](Dirt/Dirt/Core/Design/README.md)** - Material Glass components and guidelines
- **[Navigation](Dirt/Dirt/Core/Navigation/README.md)** - Navigation coordination and routing
- **[Features](Dirt/Dirt/Features/README.md)** - Feature module organization and patterns
- **[Shared Components](Dirt/Dirt/Shared/README.md)** - Cross-feature utilities and models

## Contributing

PRs welcome! Please follow our development guidelines:

1. **Read the [Coding Standards](docs/CODING_STANDARDS.md)** before contributing
2. **Follow feature boundaries** - don't create cross-feature dependencies
3. **Use Material Glass components** from the design system
4. **Include accessibility support** in all UI changes
5. **Add comprehensive tests** for new functionality
6. **Update documentation** when making architectural changes

### Code Review Checklist
- [ ] Follows coding standards and architecture patterns
- [ ] Includes proper Material Glass implementation
- [ ] Has accessibility support (VoiceOver, Dynamic Type, etc.)
- [ ] Includes unit tests and integration tests
- [ ] Updates relevant documentation
