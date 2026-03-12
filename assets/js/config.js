// ─────────────────────────────────────────────────────────────────────────────
// CineLog Pro – Runtime Configuration
// You can override these at deploy time via: window.__CINELOG_ENV__
// Example:
// <script>window.__CINELOG_ENV__={SUPABASE_URL:'...',SUPABASE_ANON_KEY:'...',TMDB_KEY:'...'}</script>
// ─────────────────────────────────────────────────────────────────────────────
const __env = window.__CINELOG_ENV__ || {};
window.CINELOG_CONFIG = {
  // Supabase – get from: https://app.supabase.com → Project Settings → API
  SUPABASE_URL: __env.SUPABASE_URL || 'https://fvrhagqwdbllnjyqtpfp.supabase.co',
  SUPABASE_ANON_KEY: __env.SUPABASE_ANON_KEY || 'sb_publishable_We-75r2r46uvbvOux3FTWw_ENbpdI5h',

  // TMDB (The Movie Database) – get from: https://www.themoviedb.org/settings/api
  TMDB_KEY: __env.TMDB_KEY || '849b72ab31fb69f120ef8c5df5c5f7d0'
};
