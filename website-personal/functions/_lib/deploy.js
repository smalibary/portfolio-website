// Fire-and-forget deploy hook trigger. Calling this after a successful
// admin write kicks off a fresh Cloudflare Pages build so the change goes
// live in ~90 seconds without any manual git push.
//
// The hook URL is set as DEPLOY_HOOK_URL on Cloudflare Pages (one per
// environment). Created via:
//   POST /accounts/<id>/pages/projects/<project>/deploy_hooks
//
// Returns nothing useful — we don't block the admin response on the
// rebuild starting. If the hook isn't configured we just log and move on.

export function triggerRebuild(env, ctx) {
  if (!env.DEPLOY_HOOK_URL) {
    console.warn('DEPLOY_HOOK_URL not set — admin save will not trigger a rebuild.');
    return;
  }
  const promise = fetch(env.DEPLOY_HOOK_URL, { method: 'POST' })
    .then((r) => {
      if (!r.ok) {
        console.error('Deploy hook fired but returned', r.status);
      }
    })
    .catch((e) => {
      console.error('Deploy hook fetch failed:', e.message || e);
    });

  // waitUntil keeps the Worker alive long enough to send the hook even
  // after the admin response is returned to the client.
  if (ctx && typeof ctx.waitUntil === 'function') {
    ctx.waitUntil(promise);
  }
}
