# Dirt v1.0

Dirt is a male-focused, privacy-first dating feedback app (SwiftUI + Supabase). This repo contains the iOS app, backend infrastructure (Supabase), and documentation.

## Layout
- `Dirt/` — iOS app project (SwiftUI)
- `backend/` — Supabase (Postgres, Auth, Storage, Edge Functions)
- `docs/` — Whitepaper, reference assets, and docs index
- `.backups/` — Timestamped backups (code-safety only; excluded from VCS)

## iOS App
- Entry: `Dirt/Dirt/`
- Features in `Dirt/Dirt/Features/`
- Shared models/services/utils in `Dirt/Shared/`
- Core subsystems in `Dirt/Core/`

### Implemented UX (v1)
- Feed/Post actions: Helpful (👍), Save, Share, Report with reason sheet and soft-hide
- Search: Saved searches and typeahead suggestions; quick filters (Recent/Popular/Nearby/Trending)
- Create Post: required Red/Green flag, controlled tags, 500-char limit; optional photo auto-blurred with EXIF strip stub
- Notifications: Activity and Keyword Alerts tabs
- Profile: Anonymous shell with Saved and Liked placeholders

### Design System
- Tokens: `Dirt/Dirt/UI/Design/DesignTokens.swift`
- Card style: `Dirt/Dirt/UI/Design/CardStyles.swift`

### Utilities & Moderation
- Validation + ReportReason: `Dirt/Dirt/Utilities/Validation.swift`
- ReportService (stub): `Dirt/Dirt/Utilities/ReportService.swift` (centralizes report submission)
- ModerationQueue (stub): `Dirt/Dirt/Utilities/ModerationQueue.swift` (auto-hide threshold)
- Image processing: `Dirt/Dirt/Utilities/ImageProcessing.swift` (blur + EXIF strip stub)

## Backend
See `backend/README.md` for setup, env, migrations, RLS, and security.

## Docs
- `docs/whitepaper_dirt.md` — MVP whitepaper
- `docs/Tea/` — Reference screenshots (not shipped)

## Security & Privacy
- Minimal PII, anonymous-first
- Strict RLS in Postgres
- Signed URLs for media, EXIF stripped on device
 - In-app reporting with local soft-hide and auto-hide threshold (see `SECURITY.md`)

## Getting Started
1) iOS: open `Dirt/Dirt.xcodeproj` and build for iPhone
2) Backend: follow `backend/README.md`

## Contributing
PRs welcome. Please keep changes small and documented. Add/update READMEs when creating new modules.
