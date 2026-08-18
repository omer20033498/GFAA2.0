-- Community group: one single admin-managed group. Apply in the Supabase
-- SQL Editor (or `supabase db push`) for the project referenced in .env
-- before running the app against this branch.
--
-- Author names are snapshotted onto each post/comment at write time
-- (author_display_name) rather than joined live from `profiles` — profiles
-- SELECT is owner-only (see migration 0001), and loosening that to let
-- users read each other's names is the kind of RLS change CLAUDE.md says
-- to ask about first. Snapshotting sidesteps it; the tradeoff is a post
-- shows the name as it was at posting time, not any later change.

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users (id) on delete cascade,
  author_display_name text not null,
  body text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create index if not exists community_posts_status_created_at_idx
  on public.community_posts (status, created_at desc);

alter table public.community_posts enable row level security;

-- Approved posts are visible to everyone; a user also sees their own posts
-- regardless of status (so they know if it's pending/rejected); admins see
-- everything, for moderation.
create policy "View approved posts, own posts, or all posts as admin"
  on public.community_posts for select
  to authenticated
  using (
    status = 'approved'
    or author_id = auth.uid()
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "Authenticated users can create their own posts"
  on public.community_posts for insert
  with check (author_id = auth.uid());

create policy "Only admins can update post status"
  on public.community_posts for update
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- Admin can delete any post — their own or anyone else's.
create policy "Only admins can delete posts"
  on public.community_posts for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- Forces the real status server-side regardless of what the client sends:
-- admin posts go live immediately, everyone else's need approval. Mirrors
-- profiles' prevent_role_self_escalation trigger (migration 0001).
create or replace function public.set_community_post_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
    new.status := 'approved';
  else
    new.status := 'pending';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_set_community_post_status on public.community_posts;
create trigger trg_set_community_post_status
  before insert on public.community_posts
  for each row execute function public.set_community_post_status();

alter publication supabase_realtime add table public.community_posts;

create table if not exists public.community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts (id) on delete cascade,
  author_id uuid not null references auth.users (id) on delete cascade,
  author_display_name text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists community_comments_post_id_created_at_idx
  on public.community_comments (post_id, created_at);

alter table public.community_comments enable row level security;

-- Comments aren't moderated (only posts are, per spec) and aren't
-- sensitive, so read access is open the same way daily_messages is.
create policy "Any authenticated user can view comments"
  on public.community_comments for select
  to authenticated
  using (true);

create policy "Authenticated users can create their own comments"
  on public.community_comments for insert
  with check (author_id = auth.uid());

create policy "Users can delete their own comments"
  on public.community_comments for delete
  using (author_id = auth.uid());

create policy "Admins can delete any comment"
  on public.community_comments for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

alter publication supabase_realtime add table public.community_comments;
