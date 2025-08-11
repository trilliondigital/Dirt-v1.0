-- Dirt v1.0 initial schema and RLS
-- Tables: posts, reports, tags, sentiments, saved_searches, mentions
-- NOTE: Adjust UUID generation and auth schema references to your project.

create extension if not exists "uuid-ossp";

-- Users are managed by Supabase auth; reference via uuid

create table if not exists public.posts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null,
  content text not null check (char_length(content) <= 500),
  tags text[] not null default '{}',
  has_media boolean not null default false,
  media_url text,
  blur_default boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  reporter_id uuid not null,
  reason text not null,
  notes text,
  status text not null default 'pending' check (status in ('pending','reviewed','actioned','dismissed')),
  created_at timestamptz not null default now()
);

create table if not exists public.tags (
  id serial primary key,
  name text unique not null,
  sentiment text not null check (sentiment in ('positive','negative','neutral'))
);

create table if not exists public.sentiments (
  post_id uuid primary key references public.posts(id) on delete cascade,
  score numeric not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.saved_searches (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null,
  query text not null,
  tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.mentions (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  mentioned text not null,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_posts_user on public.posts(user_id);
create index if not exists idx_reports_post on public.reports(post_id);
create index if not exists idx_saved_searches_user on public.saved_searches(user_id);
create index if not exists idx_mentions_post on public.mentions(post_id);

-- RLS
alter table public.posts enable row level security;
alter table public.reports enable row level security;
alter table public.saved_searches enable row level security;
alter table public.sentiments enable row level security;
alter table public.mentions enable row level security;

-- Basic policies; adjust roles/claims as needed
-- Assumes auth.uid() returns user uuid.

-- posts: owner can read/write; others can read if not hidden (soft-hide via function/column if desired)
create policy posts_select on public.posts
for select using (true);

create policy posts_insert on public.posts
for insert with check (auth.uid() = user_id);

create policy posts_update on public.posts
for update using (auth.uid() = user_id);

-- reports: reporter can insert; moderators can read; reporter can read own
create policy reports_insert on public.reports
for insert with check (auth.uid() = reporter_id);

create policy reports_select_own on public.reports
for select using (auth.uid() = reporter_id);

-- TODO: add a role/claim check for moderators, e.g., request.jwt.claims ->> 'role' = 'moderator'
-- Example:
-- create policy reports_select_moderator on public.reports
-- for select using ((current_setting('request.jwt.claims', true)::jsonb ->> 'role') = 'moderator');

-- saved_searches: owner only
create policy saved_searches_select on public.saved_searches
for select using (auth.uid() = user_id);

create policy saved_searches_insert on public.saved_searches
for insert with check (auth.uid() = user_id);

create policy saved_searches_delete on public.saved_searches
for delete using (auth.uid() = user_id);

-- mentions: readable by all; write via server-side function only (no direct insert)
create policy mentions_select on public.mentions
for select using (true);

-- sentiments: readable by all; updated by server-side jobs/functions
create policy sentiments_select on public.sentiments
for select using (true);
