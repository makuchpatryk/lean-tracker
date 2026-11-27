create table public.recents (
  user_id          uuid not null references auth.users(id) on delete cascade,
  product_key      text not null check (product_key ~ '^(off|own):.+'),
  product_snapshot jsonb not null check (jsonb_typeof(product_snapshot) = 'object'),
  last_quantity    numeric(7,1) not null check (last_quantity between 0.1 and 10000),
  last_unit        text not null,
  last_used_at     timestamptz not null,
  updated_at       timestamptz not null,
  primary key (user_id, product_key)
);
alter table public.recents enable row level security;
revoke all on public.recents from anon, authenticated;
