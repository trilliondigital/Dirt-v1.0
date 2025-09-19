# Dirt Backend (Supabase) — Production-Ready Guide

This backend powers the Dirt iOS app (male counterpart to “Tea”). It uses Supabase (Postgres + Auth + Storage + Edge Functions) with strict RLS, minimal PII, and strong moderation.

## Stack
- Postgres (Supabase Managed or Local via Docker)
- Supabase Auth (Sign in with Apple required for App Store compliance)
- Supabase Storage (signed URLs, EXIF stripped client-side)
- Edge Functions (moderation hooks, webhooks)

## Repository Layout
```
backend/
├─ migrations/            # SQL migrations (DDL only)
├─ supabase/              # Supabase config (CLI managed)
├─ config/                # Env templates and project config
├─ setup_supabase.sh      # One-shot local bootstrap
└─ README.md              # This file
```

## Prerequisites
- Docker Desktop (for local Supabase)
- Supabase CLI: `brew install supabase/tap/supabase`
- Node 18+ (Edge function tooling)

## Environment
Create `.env.local` in `backend/` (never commit secrets):
```
SUPABASE_ANON_KEY=...           # anon public key (mobile)
SUPABASE_SERVICE_ROLE_KEY=...   # service role (server-only)
SUPABASE_URL=http://localhost:54321
```
For production, set the same keys in your CI or environment manager.

## Local Development
1) Start stack
```bash
cd backend
chmod +x setup_supabase.sh
./setup_supabase.sh       # runs `supabase start` and applies migrations
```
Access Studio: http://localhost:54323

2) Apply migrations after schema edits
```bash
supabase migration new add_reviews_index
# edit migrations/<timestamp>_add_reviews_index.sql
supabase db reset         # rebuild local db from migration history
```

3) Generate types (optional for server codegen)
```bash
supabase gen types typescript --local --schema public > config/db.types.ts
```

## Schema Overview (public)
- `users` (UUID PK, apple_id unique, created_at, last_active, reputation_score, is_admin)
- `reviews` (UUID PK, user_id FK, flag_type enum [red|green], category text, tags text[], body text, media_url text, created_at)
- `votes` (user_id, review_id, value int [-1|0|1])
- `reports` (id, review_id, reporter_id, reason text, status enum [open|closed], created_at)
- `alerts` (id, user_id, keywords text[], enabled bool)

All tables have RLS enabled by default.

## RLS Policies (essentials)
- users: `select` own row; admin can `select` all. Updates limited to `last_active` by self.
- reviews: `insert` when `auth.uid() = user_id`; `select` all; `update/delete` by owner or admin.
- votes: `insert/update` when `auth.uid() = user_id`; one vote per (user, review).
- reports: `insert` by any authenticated; `select` own or admin.
- alerts: `insert/select/update/delete` by owner only.

See `migrations/*_rls_policies.sql` for exact SQL. Always validate with `supabase db reset` locally.

## Storage
- Bucket: `media`
- Policy: only owner can upload/delete own objects; read is public for post media OR served via signed URL per product decision.
- Client uploads should:
  - remove EXIF
  - generate safe filenames (uuid)
  - optionally blur by default

## Edge Functions (suggested)
- `moderate-review`: run content through moderation API before insert (or post-insert with quarantine flag)
- `webhook-analytics`: collect aggregated, non-PII metrics

## Mobile Integration (iOS)
In app, configure once in `SupabaseManager.swift`:
- URL: production URL in Release; localhost when running simulator with port-forwarding
- Auth: Sign in with Apple; persist session securely
- Storage: use signed URL fetch or public reads per bucket policy

## Migrations Workflow
1. Create migration: `supabase migration new <name>`
2. Edit SQL (DDL only)
3. Test: `supabase db reset`
4. Commit migration files
5. Deploy: CI uses `supabase db push` (or GitHub Action) against staging/prod

## Security Checklist
- RLS ON for every table; no table without RLS
- Service role key NEVER ships in app builds
- Limit `select` columns where possible using views
- Rate-limit writes via Edge Functions if needed
- Validate and sanitize tags/body server-side
- Delete media on review deletion via trigger or function

## Troubleshooting
- Ports in use: `supabase stop` then `supabase start`
- Reset local DB: `supabase db reset`
- Auth issues: clear sessions, check Studio Auth settings
- Storage 403: verify bucket policies and JWT claims

## References
- Supabase Docs: https://supabase.com/docs
- RLS Guide: https://supabase.com/docs/guides/auth/row-level-security
- Postgres Docs: https://www.postgresql.org/docs/

---
Proprietary and confidential. © Dirt.
