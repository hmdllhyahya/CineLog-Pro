# Supabase Setup (Starter)

This repository now includes Supabase foundations for the next implementation phase.

## Files added
- `.env.example` — placeholder variables for project URL and anon key.
- `assets/js/config.js` — runtime config used by static front-end.
- `assets/js/supabase-bootstrap.js` — initializes `window.supabaseClient` safely.
- `supabase/schema.sql` — starter schema + trigger + RLS policies.

## Quick start
1. Create a Supabase project.
2. Open `assets/js/config.js` and fill:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. Run SQL in Supabase SQL Editor:
   - paste `supabase/schema.sql`
4. Reload app.

If config is empty, app will keep running in local-only mode (existing behavior).

## Notes
- This is a **foundation** layer, not full migration yet.
- Current UI still reads hardcoded/mock data and localStorage; DB reads/writes are next step.
