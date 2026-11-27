create table public.user_settings (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  goal_kcal      integer not null check (goal_kcal between 500 and 10000),
  goal_protein_g integer not null check (goal_protein_g between 0 and 1000),
  goal_fat_g     integer not null check (goal_fat_g between 0 and 1000),
  goal_carbs_g   integer not null check (goal_carbs_g between 0 and 1000),
  updated_at     timestamptz not null
);
alter table public.user_settings enable row level security;
revoke all on public.user_settings from anon, authenticated;
