-- Adds a `full_name` column and populates both `display_name` and
-- `full_name` from sign-up metadata. Apply in the Supabase SQL Editor (or
-- `supabase db push`) for the project referenced in .env before running the
-- app against this branch.

alter table public.profiles
  add column if not exists full_name text;

-- Register screen now collects a required "preferred name" (shown anywhere
-- the app displays the user's name -> profiles.display_name) and an
-- optional "full name" (records only, never shown -> profiles.full_name).
-- Both are passed as auth signUp `data` and land in
-- auth.users.raw_user_meta_data, which this trigger reads.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role, display_name, full_name)
  values (
    new.id,
    new.email,
    'user',
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'full_name'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
