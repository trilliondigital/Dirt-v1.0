# Dirt Runbook

This runbook documents day-2 operations for the Dirt app: backend deploys, database migrations, app configuration, feature toggles, and common troubleshooting.

## Architecture overview
- iOS app (SwiftUI) in `Dirt/`
- Supabase (Postgres, Auth, Storage, Edge Functions) in `backend/`
- Edge Functions used:
  - `posts-create` — validated post creation
  - `moderation-submit`, `moderation-queue`, `moderation-update`
  - `saved-searches-list`, `saved-searches-save`, `saved-searches-delete`
  - `interests-save`
  - `search-global`
  - `mentions-process` (scaffold)
  - `media-process` (scaffold)

## Prerequisites
- Supabase CLI installed and logged in
- Access to the Supabase project (org + project)
- iOS build environment (Xcode 15+)
- Secrets available for local/dev/prod

## Environment configuration
- iOS app expects Supabase URL and anon key from build configuration (xcconfig or build settings). Do not hardcode.
- Keep `Config.example.xcconfig` as a template (do not commit real secrets).

## Database migrations
- Migrations are in `backend/migrations/`.
- Apply using Supabase CLI (from `backend/`):
  - `supabase db push` to apply local migrations to the linked project
  - Verify RLS policies for all tables (Posts, Reports, SavedSearches, Tags, Sentiments)

## Deploy Edge Functions
From `backend/functions/`:
1) Ensure each function has an `index.ts` and compiles under Supabase Edge runtime.
2) Deploy functions (examples):
```
supabase functions deploy posts-create
supabase functions deploy moderation-submit
supabase functions deploy moderation-queue
supabase functions deploy moderation-update
supabase functions deploy saved-searches-list
supabase functions deploy saved-searches-save
supabase functions deploy saved-searches-delete
supabase functions deploy interests-save
supabase functions deploy search-global
supabase functions deploy mentions-process
supabase functions deploy media-process
```
3) Assign appropriate access (anon/ service role) and verify RLS contracts.

## iOS build + release
- Open `Dirt/Dirt.xcodeproj` and build target `Dirt`.
- Ensure the correct scheme and configuration (Debug/Release) with proper Supabase env values.
- For App Store readiness: icons, splash, screenshots, and policies must be set (see `docs/`).

## Feature toggles and fallbacks
- Backend toggles exist in services to fall back to local stubs on failure (e.g., SearchService, ModerationService).
- Use toasts for user-visible errors and instrument analytics for failures.

## Observability
- Analytics via `AnalyticsService`: time-to-first-post, helpful/report rates, moderation queue actions.
- Supabase logs: API, Postgres, Edge Functions (use Supabase dashboard or CLI to fetch logs).

## Common playbooks
- Search returns empty unexpectedly:
  - Check `search-global` logs; verify payload, RLS policies, and indices.
  - If backend degraded, `SearchService` fallback should return mock data; confirm cache not masking changes.
- Report actions fail:
  - Check `moderation-submit` and `moderation-update` logs. Validate auth token presence.
  - Client shows `ErrorPresenter`-based toast; capture error parameters in analytics.
- Mentions not processing:
  - Verify `mentions-process` deployed; confirm payload includes `post_id` and `mentions`.
- Media hash/EXIF:
  - `media-process` computes content hash. Server-side EXIF stripping is pending; keep client-side stripping until finalized.

## Troubleshooting checklist
- Confirm Supabase URL/key are present for the current build configuration.
- Check RLS policy diffs after migrations.
- Tail Edge Function logs for recent requests.
- Validate Storage signed URL expiry and bucket ACLs.
- Run unit tests (Xcode Test): Retry, MentionsService, SearchService.

## Disaster recovery
- Revert to previous function version via Supabase (functions keep versions).
- Reset dev branch database if drifted (Supabase branching, if enabled).
- Roll back migrations by applying prior snapshot (ensure backups exist).

## Contacts
- Security: see `SECURITY.md` for responsible disclosure notes.
- Operations: repository CODEOWNERS or on-call rotation.
