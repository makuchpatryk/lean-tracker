create table public.favorites (
  id               uuid primary key,
  user_id          uuid not null references auth.users(id) on delete cascade,
  product_key      text not null check (product_key ~ '^(off|own):.+'),
  product_snapshot jsonb not null check (jsonb_typeof(product_snapshot) = 'object'),
  updated_at       timestamptz not null,
  deleted_at       timestamptz
);
-- Unique on live rows only, same rule as the products barcode (D-68).
create unique index favorites_user_key_live_key
  on public.favorites (user_id, product_key) where deleted_at is null;
alter table public.favorites enable row level security;
revoke all on public.favorites from anon, authenticated;
