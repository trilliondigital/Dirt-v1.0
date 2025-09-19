-- Enable RLS on all tables
alter table users enable row level security;
alter table reviews enable row level security;
alter table tags enable row level security;
alter table review_tags enable row level security;
alter table flags enable row level security;
alter table moderation_actions enable row level security;
alter table alerts enable row level security;

-- Users policies
create policy "Users can view their own profile"
on users for select
using (auth.uid() = id);

create policy "Users can update their own profile"
on users for update
using (auth.uid() = id);

-- Reviews policies
create policy "Public reviews are viewable by everyone"
on reviews for select
using (is_visible = true);

create policy "Users can view their own reviews"
on reviews for select
using (auth.uid() = user_id);

create policy "Users can insert their own reviews"
on reviews for insert
with check (auth.uid() = user_id);

create policy "Users can update their own reviews"
on reviews for update
using (auth.uid() = user_id);

create policy "Users can delete their own reviews"
on reviews for delete
using (auth.uid() = user_id);

-- Flags policies
create policy "Users can flag content"
on flags for insert
with check (auth.uid() = user_id);

create policy "Users can view their own flags"
on flags for select
using (auth.uid() = user_id);

-- Moderation actions (admin only)
create policy "Only moderators can perform actions"
on moderation_actions for all
using (exists (
  select 1 from users 
  where id = auth.uid() 
  and is_moderator = true
));

-- Alerts policies
create policy "Users can manage their own alerts"
on alerts for all
using (auth.uid() = user_id);

-- Storage policies (for profile pictures)
-- Note: These require the storage extension to be enabled in Supabase
create policy "Profile pictures are publicly accessible"
on storage.objects for select
using (bucket_id = 'profile-pictures');

create policy "Users can upload their own profile picture"
on storage.objects for insert
with check (
  bucket_id = 'profile-pictures' 
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update their own profile picture"
on storage.objects for update
using (
  bucket_id = 'profile-pictures' 
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Enable realtime for reviews
create publication supabase_realtime;
alter publication supabase_realtime add table reviews;
