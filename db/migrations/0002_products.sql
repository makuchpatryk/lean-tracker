create table public.products (
  id              uuid primary key,
  owner_id        uuid not null references auth.users(id) on delete cascade,
  name            text not null check (char_length(name) between 1 and 120),
  brand           text check (brand is null or char_length(brand) <= 80),
  barcode         text check (barcode is null or barcode ~ '^[0-9]{8,13}$'),
  base_unit       text not null check (base_unit in ('g', 'ml')),
  kcal_per_100    numeric(6,1) not null check (kcal_per_100 between 0 and 9999),
  protein_per_100 numeric(5,1) not null check (protein_per_100 between 0 and 100),
  fat_per_100     numeric(5,1) not null check (fat_per_100 between 0 and 100),
  carbs_per_100   numeric(5,1) not null check (carbs_per_100 between 0 and 100),
  serving_size    numeric(7,1) check (serving_size is null or serving_size between 0.1 and 10000),
  is_shared       boolean not null default false,
  updated_at      timestamptz not null,
  deleted_at      timestamptz
);
-- "unique per owner" applies to live rows, so a deleted product's barcode can be reused (D-68).
create unique index products_owner_barcode_live_key
  on public.products (owner_id, barcode) where barcode is not null and deleted_at is null;
create index products_owner_idx on public.products (owner_id);
alter table public.products enable row level security;
revoke all on public.products from anon, authenticated;
