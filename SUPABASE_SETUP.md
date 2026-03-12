# Supabase Setup (CineLog Runtime)

## Source of truth schema
Use **`supabase/cl_schema.sql`** for this app runtime.

`supabase/schema.sql` is legacy/starter reference and should not be used for current `cl_*` app tables.

## Quick start
1. Create/open your Supabase project.
2. In **Settings → API**, copy:
   - Project URL
   - Publishable key
3. Set runtime config in `assets/js/config.js` (or inject `window.__CINELOG_ENV__`).
4. Run SQL in Supabase SQL Editor:
   - paste `supabase/cl_schema.sql`
5. Reload app and verify auth/login works.

## Notes
- Frontend must use **publishable key**, never secret key.
- Connect Plus reads from `public.cl_user_directory`.
- Profile ID is expected from DB-backed `public_id` field.
