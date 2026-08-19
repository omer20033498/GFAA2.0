-- Google sign-in populates raw_user_meta_data.full_name (via Supabase's
-- OAuth provider normalization), not display_name -- only email/password
-- sign-up ever sets display_name directly (see RegisterScreen). Without
-- this, a Google sign-up would fall back to Profile.effectiveDisplayName's
-- email-prefix default instead of showing their actual name. Apply in the
-- Supabase SQL Editor (or `supabase db push`) for the project referenced
-- in .env before running the app against this branch.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  is_practitioner_application boolean := coalesce(
    (new.raw_user_meta_data ->> 'practitioner_application')::boolean, false
  );
begin
  insert into public.profiles (id, email, role, display_name, full_name)
  values (
    new.id,
    new.email,
    'user',
    coalesce(new.raw_user_meta_data ->> 'display_name', new.raw_user_meta_data ->> 'full_name'),
    new.raw_user_meta_data ->> 'full_name'
  )
  on conflict (id) do nothing;

  if is_practitioner_application then
    insert into public.practitioners (
      user_id, full_name, email, phone, profession, qualifications,
      expertise, state, location, delivery_options, website
    )
    values (
      new.id,
      new.raw_user_meta_data ->> 'full_name',
      new.email,
      new.raw_user_meta_data ->> 'phone',
      new.raw_user_meta_data ->> 'profession',
      new.raw_user_meta_data ->> 'qualifications',
      new.raw_user_meta_data ->> 'expertise',
      new.raw_user_meta_data ->> 'state',
      new.raw_user_meta_data ->> 'location',
      coalesce(
        (select array_agg(value) from jsonb_array_elements_text(new.raw_user_meta_data -> 'delivery_options')),
        '{}'
      ),
      new.raw_user_meta_data ->> 'website'
    );
  end if;

  return new;
end;
$$;
