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

## Backend
See `backend/README.md` for setup, env, migrations, RLS, and security.

## Docs
- `docs/whitepaper_dirt.md` — MVP whitepaper
- `docs/Tea/` — Reference screenshots (not shipped)

## Security & Privacy
- Minimal PII, anonymous-first
- Strict RLS in Postgres
- Signed URLs for media, EXIF stripped on device

## Getting Started
1) iOS: open `Dirt/Dirt.xcodeproj` and build for iPhone
2) Backend: follow `backend/README.md`

## Contributing
PRs welcome. Please keep changes small and documented. Add/update READMEs when creating new modules.
