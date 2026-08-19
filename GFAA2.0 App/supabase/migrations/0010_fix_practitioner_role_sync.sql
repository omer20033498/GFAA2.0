-- Fixes a real bug: approving a practitioner never actually promoted their
-- profiles.role, so they landed on the normal user Home after logging in
-- instead of the Practitioner Portal.
--
-- Root cause: sync_practitioner_role() (migration 0008) is SECURITY DEFINER,
-- so it's allowed to write profiles.role -- but SECURITY DEFINER only
-- changes *privilege*, not the session's auth.role()/auth.uid(), which still
-- reflect whoever made the original request (the admin, an 'authenticated'
-- user). prevent_role_self_escalation() (migration 0001) blocks *any* role
-- change made under an 'authenticated' session -- it can't distinguish "a
-- user editing their own row" from "a trusted trigger promoting someone
-- else after an admin's approval" -- so it silently reverted the promotion
-- every time. No error was raised; the practitioners.status update itself
-- always succeeded, which is why this went unnoticed until someone actually
-- logged back in as the approved practitioner.
--
-- Fix: sync_practitioner_role() sets a transaction-local flag right before
-- its update; prevent_role_self_escalation() lets the change through when
-- that flag is set. A real client-side update (no flag set) is still
-- blocked exactly as before -- this doesn't loosen self-escalation
-- protection at all.

create or replace function public.prevent_role_self_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role
     and auth.role() = 'authenticated'
     and coalesce(current_setting('app.bypass_role_guard', true), 'false') <> 'true' then
    new.role := old.role;
  end if;
  return new;
end;
$$;

create or replace function public.sync_practitioner_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    perform set_config('app.bypass_role_guard', 'true', true);
    update public.profiles set role = 'practitioner' where id = new.user_id;
  elsif new.status is distinct from 'approved' and old.status = 'approved' then
    perform set_config('app.bypass_role_guard', 'true', true);
    update public.profiles set role = 'user' where id = new.user_id;
  end if;
  return new;
end;
$$;

-- One-time repair: promote anyone who was already approved before this fix,
-- whose profiles.role got silently reverted to 'user' by the bug above.
select set_config('app.bypass_role_guard', 'true', true);
update public.profiles p
set role = 'practitioner'
from public.practitioners pr
where pr.user_id = p.id
  and pr.status = 'approved'
  and p.role <> 'practitioner';
