-- Admin Dashboard: a "Pending / failed payments" stat -- practitioners
-- who are approved (passed review) but don't have an active subscription,
-- so they aren't actually live in the public directory yet. Distinct from
-- the existing "Live practitioners" tile, which is the opposite condition
-- (approved AND paid). Right now, with Stripe not wired up, this count
-- will just equal every approved practitioner -- that's correct, not a
-- bug: none of them can be paid up yet. Apply in the Supabase SQL Editor
-- (or `supabase db push`) for the project referenced in .env before
-- running the app against this branch.

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
    'open_bug_reports', (select count(*) from public.bug_reports where status = 'open'),
    'pending_payment_practitioners', (
      select count(*) from public.practitioners
      where status = 'approved' and not public.practitioner_has_active_subscription(id)
    )
  );
end;
$$;
