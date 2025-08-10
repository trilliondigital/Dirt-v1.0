# Dirt – UX-First Iteration Plan

## Objectives
- Clarify and fix UX before visual refresh.
- Close critical gaps vs Tea where aligned with Dirt’s vision.
- Keep IA simple, predictable, and scalable.

## Constraints & Principles
- Safety-first: no PII fields, strong reporting/moderation.
- Anonymous by default; identity never required for core flows.
- Respect Apple HIG; gestures secondary to explicit affordances.
- Visuals later: defer glass/blur/theme until UX is solid.

## Current vs Reference (Tea) – Parity Checklist
Fill this after reviewing the FigJam board in detail. Track as check items.

- Onboarding
  - [ ] Purpose + community rules screen
  - [ ] Auth: Apple Sign-In (anon token), email fallback
  - [ ] Initial interests/tags (optional) to seed feed
- Core Feed
  - [ ] Mixed red/green items with clear signal affordances
  - [ ] Sorts: Latest, Trending; Filters: Tags, Time, Proximity
  - [ ] Item actions: Helpful, Report, Save, Share
  - [ ] Media handling: blurred-by-default; tap to reveal
- Search & Discovery
  - [ ] Global search (tags, sentiments)
  - [ ] Quick filters (Recent/Popular/Nearby/Trending)
  - [ ] Typeahead suggestions
- Create Post
  - [ ] Red/Green required; category (relationship type)
  - [ ] Tags (controlled vocab)
  - [ ] 500-char limit + live counter
  - [ ] Optional photo (auto-blur, strip EXIF)
- Notifications & Alerts
  - [ ] Mentions of your content (likes, reports)
  - [ ] Keyword alerts (saved searches)
- Profile
  - [ ] Anonymous profile shell (no public PII)
  - [ ] Saved posts, Liked posts
- Moderation
  - [ ] Report flow (reason codes)
  - [ ] Auto-hide threshold + queue

Record deltas here:
- Missing: …
- Broken: …
- Divergent (keep vs change): …

## Proposed Information Architecture
- Tabs: Feed | Search | Post | Alerts | Profile
- Feed: home timeline, filters bar (pills), infinite scroll.
- Search: query + result groups (Tags, Posts), saved searches.
- Post: modal sheet, single path, short form.
- Alerts: activity and keyword alerts.
- Profile: saved, liked, app settings entry.

## Primary User Flows (v2)
1) First-run → Rules → Sign in (Apple) → Seed interests → Feed
2) Feed → Filter (Trending/Tag) → Post detail → Report/Helpful
3) Create post → Validate → Submit → Success state
4) Search → Saved search → Enable alerts
5) Alert tap → Filtered feed or post detail

## Navigation Model
- Root `TabView` (5 tabs). Each tab uses `NavigationStack`.
- Global compose button is the center tab to avoid FAB conflicts.

## Interaction & Copy
- Always show explicit labels with icons (reduce ambiguity).
- “Helpful” not “Like”; “Report” prominent, never destructive by accident.
- Respect haptics sparingly; avoid noisy animations.

## Data & Content Rules
- 500 char max; no names/handles/contacts allowed (client validation).
- Tags from controlled list; map to sentiments for discovery.
- Media blurred by default; tap to reveal per session.

## Measurements (MVP)
- Time-to-first-post, post completion rate, report rate, helpful rate.

## Implementation Plan (Code refs under `Dirt/Dirt/`)
- Feed
  - Update `Features/Feed/Views/FeedView.swift`: filters bar → controlled tags; clarify item actions; add sort.
  - Add `PostDetailView` parity actions (report/helpful/save/share).
- Search
  - `Features/Search/Views/SearchView.swift`: unify filters; add saved searches section.
- Create Post
  - `Features/CreatePost/Views/CreatePostView.swift`: enforce schema (flag, category, tags, char counter, photo blur & EXIF strip stub).
- Alerts
  - `Features/Notifications/Views/NotificationsView.swift`: separate Activity vs Keyword tabs.
- Profile
  - `Features/Profile/Views/ProfileView.swift`: Saved, Liked; Settings entry only (no PII edit).
- Shared
  - Controlled tags list + validation in `Shared/Models` and simple `Shared/Utils/Validation`.
- Moderation
  - Report sheet with reasons in post card; soft-hide flag in view model.

## Visual Layer (Later)
- After UX stabilizes: apply iOS “glass” via `Material` (e.g., `.ultraThinMaterial`) for bars, cards, sheets; dynamic color tokens in `Core/UI/DesignSystem.swift`.

## Milestones
- M1: Parity analysis complete (FigJam) + checklist updated
- M2: Create Post v2 + Feed actions parity
- M3: Search/saved searches + Alerts (keyword)
- M4: Report flow + soft-hide
- M5: Visual polish (glass, dark), QA, TestFlight

## Open Questions
- Which Tea features to explicitly not replicate?
- Any geo-specific constraints (Nearby)?
- Referral/monetization timing for MVP?
