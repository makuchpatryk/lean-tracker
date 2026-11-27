-- Local stand-in for Supabase Auth (M1, local only).
-- Not a migration, never applied to a hosted project. A no-op when the image already provides
-- auth.users, anon and authenticated (supabase/postgres does); creates them on a plain Postgres.
do $$ begin
  if to_regclass('auth.users') is null then
    create schema if not exists auth;
    create table auth.users (id uuid primary key);
  end if;
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
end $$;
