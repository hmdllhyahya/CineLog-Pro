(function initSupabase() {
  const cfg = window.CINELOG_CONFIG || {};
  const url = cfg.SUPABASE_URL || '';
  const anonKey = cfg.SUPABASE_ANON_KEY || '';

  if (!window.supabase || typeof window.supabase.createClient !== 'function') {
    console.warn('[CineLog] Supabase SDK is not loaded yet.');
    window.supabaseReady = Promise.resolve(null);
    return;
  }

  if (!url || !anonKey) {
    console.info('[CineLog] Supabase config is empty. App continues in local-only mode.');
    window.supabaseClient = null;
    window.supabaseReady = Promise.resolve(null);
    return;
  }

  try {
    const client = window.supabase.createClient(url, anonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      }
    });

    window.supabaseClient = client;
    window.supabaseReady = client.auth.getSession().then(({ error }) => {
      if (error) {
        console.warn('[CineLog] Supabase session check failed:', error.message);
      }
      return client;
    });
  } catch (error) {
    console.error('[CineLog] Failed to initialize Supabase client:', error);
    window.supabaseClient = null;
    window.supabaseReady = Promise.resolve(null);
  }
})();
