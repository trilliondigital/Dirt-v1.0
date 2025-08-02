-- Enable necessary extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- 👤 Users table (anonymous auth)
create table users (
  id uuid primary key default uuid_generate_v4(),
  email text unique,
  is_verified boolean default false,
  is_moderator boolean default false,
  created_at timestamp with time zone default now(),
  last_active timestamp with time zone default now(),
  report_count integer default 0,
  constraint email_or_anon check (email is not null or id::text = auth.uid()::text)
);

-- 🔑 Enable Row Level Security
alter table users enable row level security;

-- 🔍 Reviews (main content)
create table reviews (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null check (length(title) between 5 and 100),
  content text not null check (length(content) between 10 and 500),
  image_url text,
  is_visible boolean default true,
  helpful_votes integer default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint fk_user foreign key(user_id) references auth.users(id)
);

-- 🏷️ Tags
create table tags (
  id serial primary key,
  name text unique not null,
  sentiment text check (sentiment in ('positive', 'negative')),
  usage_count integer default 0
);

-- 🔗 Review-Tag many-to-many relationship
create table review_tags (
  review_id uuid references reviews(id) on delete cascade,
  tag_id integer references tags(id) on delete cascade,
  primary key (review_id, tag_id)
);

-- ⚠️ Community Flags (moderation)
create table flags (
  id uuid primary key default uuid_generate_v4(),
  review_id uuid references reviews(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  reason text not null,
  created_at timestamp with time zone default now(),
  unique(review_id, user_id)  -- Prevent duplicate flags
);

-- ✅ Mod Actions
declare
  mod_action_type text[] := array['hide', 'delete', 'warn', 'ban_user'];
begin
  if not exists (select 1 from pg_type where typname = 'mod_action_type') then
    create type mod_action_type as enum (
      'hide', 'delete', 'warn', 'ban_user'
    );
  end if;
end;
$$;

create table moderation_actions (
  id uuid primary key default uuid_generate_v4(),
  review_id uuid references reviews(id) on delete cascade,
  admin_id uuid references auth.users(id),
  action mod_action_type not null,
  note text,
  created_at timestamp with time zone default now()
);

-- 🔔 Alerts (opt-in keyword notifications)
create table alerts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  keyword text not null,
  created_at timestamp with time zone default now(),
  unique(user_id, keyword)  -- Prevent duplicate alerts
);

-- 🔄 Create function to update timestamps
create or replace function update_modified_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language 'plpgsql';

-- ⏱️ Add updated_at trigger to reviews
create trigger update_reviews_modtime
  before update on reviews
  for each row
  execute function update_modified_column();

-- 🔍 Create indexes for performance
create index idx_reviews_user_id on reviews(user_id);
create index idx_reviews_created_at on reviews(created_at);
create index idx_flags_review_id on flags(review_id);
create index idx_review_tags_review_id on review_tags(review_id);
create index idx_review_tags_tag_id on review_tags(tag_id);
