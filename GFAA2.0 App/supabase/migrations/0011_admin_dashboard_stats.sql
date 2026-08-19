-- Admin Dashboard stat tiles: total users, live practitioners, pending
-- practitioner applications, posts awaiting approval, new signups this
-- week, and check-ins logged this week.
--
-- One SECURITY DEFINER function rather than plain client-side counts,
-- because two of these numbers can't be read any other way without
-- loosening RLS: `profiles` SELECT is owner-only (migration 0001) and
-- `checkins` SELECT is owner-only with no admin exception (migration
-- 0004, a deliberate privacy choice for personal mood/note data) --
-- neither has ever had a general admin-read policy. This function returns
-- only aggregate counts, never row content, so it doesn't expose anyone's
-- checkin notes or personal details to admin -- just how many exist.
-- Apply in the Supabase SQL Editor (or `supabase db push`) for the project
-- referenced in .env before running the app against this branch.

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
    )
  );
end;
$$;
