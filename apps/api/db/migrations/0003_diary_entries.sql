-- Snapshot columns carry no range checks (PRD §13, BR-007).
create table public.diary_entries (
  id              uuid primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  entry_date      date not null,
  meal            text not null check (meal in ('breakfast', 'lunch', 'dinner', 'snack')),
  product_name    text not null,
  source          text not null check (source in ('off', 'own', 'manual')),
  source_ref      text,
  base_unit       text not null check (base_unit in ('g', 'ml')),
  kcal_per_100    numeric(6,1) not null,
  protein_per_100 numeric(5,1) not null,
  fat_per_100     numeric(5,1) not null,
  carbs_per_100   numeric(5,1) not null,
  quantity        numeric(7,1) not null check (quantity between 0.1 and 10000),
  unit            text not null,
  serving_size    numeric(7,1),
  updated_at      timestamptz not null,
  deleted_at      timestamptz,
  constraint diary_entries_unit_check check (unit = base_unit or unit = 'serving'),
  constraint diary_entries_serving_check check (unit <> 'serving' or serving_size is not null)
);
create index diary_entries_user_date_idx on public.diary_entries (user_id, entry_date);
alter table public.diary_entries enable row level security;
revoke all on public.diary_entries from anon, authenticated;
