-- LEGACY REFERENCE ONLY
-- Current app runtime uses cl_* tables in supabase/cl_schema.sql
-- Keep this file for historical context; do not apply for current frontend runtime.

-- CineLog Pro Supabase starter schema (MVP foundation)
-- FIXED: movies table now has RLS; handle_new_user trigger is NULL-safe for anonymous auth
create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  city text,
  bio text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.movies (
  id text primary key,
  title text not null,
  year int,
  director text,
  poster_url text,
  synopsis text,
  created_at timestamptz not null default now()
);

create table if not exists public.logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  movie_id text not null references public.movies(id) on delete restrict,
  rating numeric(2,1) check (rating >= 0 and rating <= 5),
  watched_at date,
  review_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  movie_id text not null references public.movies(id) on delete restrict,
  stars numeric(2,1) check (stars >= 0 and stars <= 5),
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.lists(id) on delete cascade,
  movie_id text not null references public.movies(id) on delete restrict,
  position int not null default 0,
  created_at timestamptz not null default now(),
  unique (list_id, movie_id)
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followee_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);

create table if not exists public.review_likes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  review_id uuid not null references public.reviews(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, review_id)
);

create table if not exists public.review_comments (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null references public.reviews(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

-- ── Trigger: auto-create profile on new user ─────────────────────────────────
-- FIX: NULL-safe for anonymous auth (email is NULL for anonymous users)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  _username text;
begin
  if new.email is not null and new.email <> '' then
    _username := split_part(new.email, '@', 1);
  else
    _username := 'user_' || substr(new.id::text, 1, 8);
  end if;

  insert into public.profiles (id, username, display_name)
  values (new.id, _username, _username)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ── RLS ───────────────────────────────────────────────────────────────────────
alter table public.profiles      enable row level security;
alter table public.movies        enable row level security;  -- FIX: was missing
alter table public.logs          enable row level security;
alter table public.reviews       enable row level security;
alter table public.lists         enable row level security;
alter table public.list_items    enable row level security;
alter table public.follows       enable row level security;
alter table public.review_likes  enable row level security;
alter table public.review_comments enable row level security;

-- Read policies
create policy "profiles are publicly readable"    on public.profiles    for select using (true);
create policy "movies are publicly readable"      on public.movies      for select using (true);
create policy "logs are publicly readable"        on public.logs        for select using (true);
create policy "reviews are publicly readable"     on public.reviews     for select using (true);
create policy "follows are publicly readable"     on public.follows     for select using (true);
create policy "review likes are publicly readable" on public.review_likes for select using (true);
create policy "review comments are publicly readable" on public.review_comments for select using (true);

create policy "lists are publicly readable when public" on public.lists
for select using (is_public = true or owner_id = auth.uid());

create policy "list items are readable for public/owned lists" on public.list_items
for select using (
  exists (
    select 1 from public.lists l
    where l.id = list_items.list_id
      and (l.is_public = true or l.owner_id = auth.uid())
  )
);

-- Write policies
-- FIX: movies table — only authenticated users can insert/update
create policy "authenticated users can insert movies" on public.movies
for insert with check (auth.uid() is not null);

create policy "authenticated users can update movies" on public.movies
for update using (auth.uid() is not null);

create policy "users can upsert own profile" on public.profiles
for all using (id = auth.uid()) with check (id = auth.uid());

create policy "users can manage own logs" on public.logs
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "users can manage own reviews" on public.reviews
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "users can manage own lists" on public.lists
for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "users can manage items in own lists" on public.list_items
for all using (
  exists (
    select 1 from public.lists l
    where l.id = list_items.list_id and l.owner_id = auth.uid()
  )
) with check (
  exists (
    select 1 from public.lists l
    where l.id = list_items.list_id and l.owner_id = auth.uid()
  )
);

create policy "users can manage own follows" on public.follows
for all using (follower_id = auth.uid()) with check (follower_id = auth.uid());

create policy "users can manage own review likes" on public.review_likes
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "users can manage own review comments" on public.review_comments
for all using (user_id = auth.uid()) with check (user_id = auth.uid());
