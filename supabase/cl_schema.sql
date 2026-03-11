-- ─────────────────────────────────────────────────────────────────────────────
-- CineLog Pro – Application Schema (cl_* tables)
-- These are the actual tables used by the JavaScript frontend.
-- Run this in your Supabase SQL editor after enabling the pgcrypto extension.
-- ─────────────────────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";
create table if not exists public.cl_profiles (user_id uuid primary key references auth.users(id) on delete cascade, name text, username text unique, public_id text unique, bio text, location text, avatar_url text, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.cl_logs (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.cl_profiles(user_id) on delete cascade, log_id text not null, payload jsonb not null, created_at timestamptz not null default now(), unique (user_id, log_id));
create table if not exists public.cl_lists (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.cl_profiles(user_id) on delete cascade, list_id text not null, payload jsonb not null, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (user_id, list_id));
create table if not exists public.cl_friends (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.cl_profiles(user_id) on delete cascade, friend_key text not null, payload jsonb not null, created_at timestamptz not null default now(), unique (user_id, friend_key));
create table if not exists public.cl_reviews (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.cl_profiles(user_id) on delete cascade, review_key text not null, payload jsonb not null, created_at timestamptz not null default now(), unique (user_id, review_key));
create table if not exists public.cl_watchlist (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.cl_profiles(user_id) on delete cascade, watch_key text not null, payload jsonb not null, created_at timestamptz not null default now(), unique (user_id, watch_key));
create table if not exists public.cl_user_directory (user_id uuid primary key references public.cl_profiles(user_id) on delete cascade, username text unique, public_id text unique, display_name text, avatar_url text, log_count int not null default 0, updated_at timestamptz not null default now());
create or replace function public.handle_new_cinelog_user() returns trigger language plpgsql security definer set search_path = public as $$ declare _username text; begin if new.email is not null and new.email <> '' then _username := split_part(new.email, '@', 1); else _username := 'user_' || substr(new.id::text, 1, 8); end if; insert into public.cl_profiles (user_id, name, username, public_id) values (new.id, _username, _username || '_' || substr(new.id::text, 1, 4), substr(new.id::text, 1, 8)) on conflict (user_id) do nothing; return new; end; $$;
drop trigger if exists on_cinelog_user_created on auth.users;
create trigger on_cinelog_user_created after insert on auth.users for each row execute function public.handle_new_cinelog_user();
alter table public.cl_profiles enable row level security;
alter table public.cl_logs enable row level security;
alter table public.cl_lists enable row level security;
alter table public.cl_friends enable row level security;
alter table public.cl_reviews enable row level security;
alter table public.cl_watchlist enable row level security;
alter table public.cl_user_directory enable row level security;
create policy "cl_profiles public read" on public.cl_profiles for select using (true);
create policy "cl_profiles own all" on public.cl_profiles for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "cl_logs public read" on public.cl_logs for select using (true);
create policy "cl_logs own all" on public.cl_logs for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "cl_lists public read" on public.cl_lists for select using (true);
create policy "cl_lists own all" on public.cl_lists for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "cl_friends own all" on public.cl_friends for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "cl_reviews public read" on public.cl_reviews for select using (true);
create policy "cl_reviews own all" on public.cl_reviews for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "cl_watchlist own all" on public.cl_watchlist for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "cl_user_directory public read" on public.cl_user_directory for select using (true);
create policy "cl_user_directory own all" on public.cl_user_directory for all using (user_id = auth.uid()) with check (user_id = auth.uid());
