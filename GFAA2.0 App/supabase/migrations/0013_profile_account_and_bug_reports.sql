-- Profile & Account screen (delete account) and Report a Bug, per the
-- client's request to wire up the profile drawer's menu rows. Apply in the
-- Supabase SQL Editor (or `supabase db push`) for the project referenced in
-- .env before running the app against this branch.

-- Lets a signed-in user permanently delete their own account. The client
-- SDK has no self-delete method -- Supabase's admin user-deletion API needs
-- the service-role key, never exposed to the app -- so this SECURITY
-- DEFINER function does it on the caller's behalf, scoped to auth.uid()
-- only. Every feature table's user_id/id references auth.users(id) on
-- delete cascade, so this one delete also wipes their journal entries,
-- check-ins, posts, etc. IRREVERSIBLE -- test with a disposable account,
-- not a real one, before trusting this in production.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

-- Bug reports: any signed-in user can file one; only admins can read/update
-- them (surfaced in the Admin Dashboard, not emailed -- see CLAUDE.md for
-- why this was chosen over a mailto: link).
create table if not exists public.bug_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  email text not null,
  body text not null,
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_at timestamptz not null default now()
);

alter table public.bug_reports enable row level security;

create policy "Users can file their own bug reports"
  on public.bug_reports for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Admins can view all bug reports"
  on public.bug_reports for select
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "Admins can update bug report status"
  on public.bug_reports for update
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- Extends admin_dashboard_stats() (migration 0011) with an "open bug
-- reports" count, same admin-only aggregate-count pattern as the rest of
-- that function.
create or replace function public.admin_dashboard_stats()
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  is_admin boolean;
begin
  select exists(
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  ) into is_admin;

  if not is_admin then
    raise exception 'Only admins can read dashboard stats';
  end if;

  return jsonb_build_object(
    'total_users', (select count(*) from public.profiles where role = 'user'),
    'total_practitioners', (
      select count(*) from public.practitioners
      where status = 'approved' and public.practitioner_has_active_subscription(id)
    ),
    'pending_practitioners', (select count(*) from public.practitioners where status = 'pending'),
    'pending_posts', (select count(*) from public.community_posts where status = 'pending'),
    'new_users_this_week', (
      select count(*) from public.profiles
      where role = 'user' and created_at >= now() - interval '7 days'
    ),
    'checkins_this_week', (
      select count(*) from public.checkins where created_at >= now() - interval '7 days'
    ),
    'open_bug_reports', (select count(*) from public.bug_reports where status = 'open')
  );
end;
$$;
