# Put Cloudflare in front of a Pikapods Ghost pod

Moving www.keyeracmds.com off Ghost(Pro) on 2026-07-22 cut hosting from $31 per month to about $2.50, and it also cut response time by a factor of ten in the wrong direction. The Bump uptime monitor recorded an average time-to-first-byte of roughly 65 ms on Ghost(Pro) and roughly 650 ms on the Pikapods pod. Nothing broke, nothing errored, and every page still rendered correctly - the site simply got slow.

It's not what you'd expect, but almost none of that 585 ms is Pikapods being cheap. Ghost(Pro) runs the same Ghost, the same Node, the same handlebars renderer. What Ghost(Pro) also runs is Fastly, and that is what the 65 ms was measuring: an edge cache hit from a point of presence near the monitor, which never touched Ghost at all. The migration did not lose Ghost performance. It lost a CDN.

Here's the challenge. Ghost sends `Cache-Control: public, max-age=0` on every HTML response, which is a polite instruction to any cache in the path to revalidate before reusing anything. Put a stock CDN in front of that and the CDN dutifully caches nothing, and you keep paying full render cost on every anonymous pageview. So the fix is not "add a CDN" - it is "add a CDN and override the origin's cache-control for HTML, without breaking member sign-in".

This runbook does that with Cloudflare's free plan. It applies to any Pikapods Ghost pod on a custom domain; www.keyeracmds.com and www.myorientations.com are the worked examples, both measured 2026-07-27.

## What the origin looks like before you start

Both sites return the same header set, which is what makes the whole exercise necessary:

    Cache-Control: public, max-age=0
    Content-Encoding: zstd
    Via: 1.1 Caddy
    X-Powered-By: Express

Compression is already healthy - the keyeracmds home page is 37,339 bytes of HTML that zstd delivers in 6,219. Bandwidth is not the problem. Render latency is. A bare `/favicon.ico` redirect, which does no template rendering at all, still took 342 ms cold, so the pod's CPU allocation contributes as well as Ghost.

Both sites also share a DNS shape worth understanding before you touch anything:

| Name | Type | Value | Notes |
|---|---|---|---|
| apex | A | `178.128.137.126` | DigitalOcean box running Caddy, 302s to www. **Serves both sites.** |
| `www` | CNAME | `<pod>.pikapod.net` | `resolute-boobook` for keyeracmds, `rigorous-kangaroo` for myorientations |
| nameservers | NS | `*.domaincontrol.com` | GoDaddy |

That apex redirector is shared, so it can only be retired after every site behind it has moved to Cloudflare. Until then, leave it running.

## Step 1: inventory the existing zone

- [ ] Export the zone file from GoDaddy DNS management. This is both your diff target for step 2 and your rollback.
- [ ] Identify every mail record. On keyeracmds that is: `mail` MX to `mxa`/`mxb.mailgun.org`, `mail` TXT SPF, the DKIM key at `pic._domainkey.mail`, the tracking CNAME `email.mail` to `mailgun.org`, apex SPF, and `_dmarc` TXT with three `rua` targets. **Mailgun assigns a per-domain DKIM selector**, so do not assume `pic` or `k1` - read it off the export or off the Mailgun domain page.
- [ ] Note any verification TXT records. keyeracmds carries an `ahrefs-site-verification_...` value that means nothing to you today and breaks somebody's tooling if it disappears.

Miss a mail record and nothing fails loudly. Newsletters keep sending and quietly start failing DMARC at the receiver, which you will discover from open rates a week later.

## Step 2: add the site to Cloudflare

- [ ] Add site, Free plan. Cloudflare scans the existing zone and imports what it finds.
- [ ] **Diff the imported records against your GoDaddy export, one by one.** The scanner is reliable for common types and misses long TXT values and some subdomain records. This is the single highest-risk step in the runbook and it is entirely mechanical.

## Step 3: set proxy flags and the apex redirect

The orange-cloud toggle decides whether a record is proxied through Cloudflare or served as plain DNS. Getting this wrong on mail records breaks email; getting it wrong on `www` means you did all this work for nothing.

- [ ] `www` CNAME to the pod hostname: **proxied** (orange).
- [ ] Everything under `mail.` and `email.mail.`: **DNS only** (grey).
- [ ] Delete the apex A record pointing at `178.128.137.126`. Replace it with a proxied dummy - an `A` record to `192.0.2.1` (the RFC 5737 documentation address), orange. The address is never contacted; it exists only so a rule has something to fire on.
- [ ] Rules, Redirect Rules: when hostname equals the apex, static redirect to `https://www.<domain>` plus path, status 301, preserve query string.

The redirect now happens at the edge in single-digit milliseconds instead of crossing the internet to a DigitalOcean droplet and back.

## Step 4: disable the Cloudflare defaults that break Ghost

Do this before the nameserver flip, so the settings are already correct the moment traffic arrives.

- [ ] **Rocket Loader: off.** It defers and rewrites script loading, which breaks Ghost Portal - the signup and sign-in modal.
- [ ] **Bot Fight Mode: off.** It issues challenges to non-browser clients, which includes Ghost's own Admin API calls, your webhooks, and every RSS reader subscribed to the site.
- [ ] **Email Obfuscation: off.** It injects a script into your HTML to rewrite mailto links. Harmless in theory, an unnecessary variable in a theme you did not write.
- [ ] **SSL/TLS encryption mode: Full (strict).** The pod holds a valid Let's Encrypt certificate for the custom domain, so strict verification passes. Anything weaker leaves the Cloudflare-to-origin hop unauthenticated for no benefit.
- [ ] **Always Use HTTPS: leave off for now.** Enable it in step 6, once Universal SSL reports Active. Turning it on before the edge certificate exists produces redirect loops.

## Step 5: flip the nameservers

- [ ] At GoDaddy, replace the `*.domaincontrol.com` nameservers with the two Cloudflare nameservers shown in the dashboard.
- [ ] Wait for Cloudflare to report the zone Active. Usually minutes. Universal SSL issuance is separate and can take up to 24 hours, though it is typically fast.

## Step 6: verify proxied, before caching anything

Resist the urge to add cache rules yet. Confirm the plain proxy path is intact first, so that if something breaks later you know the cache rules caused it.

- [ ] Confirm traffic is proxied:

      curl -sSI https://www.<domain>/ | grep -iE 'server|cf-ray|cf-cache-status'

  Expect `server: cloudflare` and a `cf-ray` header.

- [ ] Click through in a browser: a post page, an image, the subscribe form (expect a 201), `/ghost/` admin sign-in, and the apex redirect.
- [ ] Send yourself a member magic link and confirm it arrives. This proves the mail records survived step 2.
- [ ] Now enable **Always Use HTTPS**.

## Step 7: add the cache rules

Caching, Cache Rules. Rules evaluate in order and the first match wins for a given feature, so the bypass rule must sit above the caching rule.

**Rule 1, "Ghost dynamic bypass"** - expression:

    starts_with(http.request.uri.path, "/ghost/")
    or starts_with(http.request.uri.path, "/members/")
    or starts_with(http.request.uri.path, "/r/")
    or starts_with(http.request.uri.path, "/p/")
    or starts_with(http.request.uri.path, "/webmentions/")
    or starts_with(http.request.uri.path, "/.well-known/")
    or http.cookie contains "ghost-members-ssr"

Setting: **Bypass cache**.

Each clause earns its place:

- **`/ghost/`** is the admin interface and both the Content and Admin APIs.
- **`/members/`** creates sessions and consumes magic links. A cached response here hands one visitor another visitor's session outcome.
- **`/r/`** records newsletter click tracking. Cache it and your click statistics flatline while the links still appear to work.
- **`/p/`** serves unpublished post previews, which must never enter a shared cache.
- **`/.well-known/`** carries ACME challenges. See the certificate note at the end - this clause is load-bearing.
- **The cookie clause is the important one.** Ghost renders member-specific HTML server-side, keyed on the `ghost-members-ssr` cookie. Without this bypass, a signed-in member's personalized page can be cached and served to strangers. Everything else in this list is a correctness or analytics concern; this one is a privacy incident.

**Rule 2, "Cache HTML at edge"** - expression:

    http.host eq "www.<domain>"

Settings:

- Cache eligibility: **Eligible for cache**
- Edge TTL: **Ignore cache-control header and use this TTL**, 1 hour
- Browser TTL: **Respect origin**

That Edge TTL override is the entire fix. Without it Cloudflare obeys the pod's `max-age=0`, caches nothing, and response times do not move. Browser TTL stays at origin deliberately: visitors keep revalidating, so a purge is visible immediately rather than waiting out a stale copy in somebody's browser.

## Step 8: verify caching behavior

Four checks, all of which must pass. If any one disagrees, a rule is wrong.

    curl -sSI https://www.<domain>/ | grep -i cf-cache-status                 # MISS on first request
    curl -sSI https://www.<domain>/ | grep -i cf-cache-status                 # HIT on second
    curl -sSI -b 'ghost-members-ssr=x' https://www.<domain>/ \
      | grep -i cf-cache-status                                               # BYPASS
    curl -sSI https://www.<domain>/ghost/ | grep -i cf-cache-status           # BYPASS

- [ ] All four match.
- [ ] Sign in as a member in a browser and confirm you see member state, not a cached anonymous page.
- [ ] Check the Bump monitor. Cache hits should land in the 20-50 ms range, better than the 65 ms Ghost(Pro) delivered. Misses stay around 650 ms, which is now a rare event rather than every pageview.

## Step 9: purge on publish

With a one-hour edge TTL, an edited post can show stale for up to an hour. Ghost can tell Cloudflare to purge, but not directly: **Ghost custom-integration webhooks cannot send an `Authorization` header**, and the Cloudflare purge API requires a bearer token. A small Worker bridges the gap.

- [ ] Create an API token: Zone, Cache Purge, Purge, scoped to this zone only. Nothing broader.
- [ ] Create a Worker with this code:

      export default {
        async fetch(req, env) {
          const url = new URL(req.url);
          if (req.method !== 'POST' || url.pathname !== `/${env.PURGE_SECRET}`) {
            return new Response('not found', { status: 404 });
          }
          const res = await fetch(
            `https://api.cloudflare.com/client/v4/zones/${env.ZONE_ID}/purge_cache`,
            {
              method: 'POST',
              headers: {
                Authorization: `Bearer ${env.CF_API_TOKEN}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({ purge_everything: true }),
            }
          );
          return new Response(res.ok ? 'purged' : 'purge failed', { status: res.ok ? 200 : 502 });
        },
      };

- [ ] Bind `CF_API_TOKEN`, `ZONE_ID`, and a random `PURGE_SECRET` as Worker secrets. The secret in the path is the only thing preventing anyone from purging your cache at will, so make it long.
- [ ] In Ghost: Settings, Integrations, add custom integration, add webhook on event **Site changed (rebuild)**, target `https://<worker>.workers.dev/<secret>`.
- [ ] Publish a test edit and confirm the change appears immediately rather than within the hour.

This step is optional. If a one-hour lag on edits is acceptable, skip it and purge by hand from the Cloudflare dashboard when it matters.

## The origin certificate trap

Full (strict) means Cloudflare validates the pod's Let's Encrypt certificate on every origin fetch. If that certificate stops renewing, the site returns `526 Invalid SSL certificate` roughly 60 days later, long after you have stopped thinking about this change.

Renewal gets harder behind a proxy. Caddy attempts TLS-ALPN validation on port 443, which now terminates at Cloudflare rather than the pod, so that method fails. It falls back to HTTP-01 on port 80, which does work: Cloudflare proxies port 80 to the origin, and it exempts `/.well-known/acme-challenge/` from Always Use HTTPS redirection. That exemption is why the `/.well-known/` clause belongs in the bypass rule, and why you should not add any redirect or firewall rule that intercepts it.

Verify rather than assume. Check the origin certificate directly, bypassing Cloudflare entirely:

    curl -sS --resolve www.<domain>:443:$(dig +short <pod>.pikapod.net | head -1) \
      -o /dev/null -w '%{ssl_verify_result}\n' https://www.<domain>/

Zero means the origin certificate is valid. Add this as a Bump check on a weekly schedule - a proxied site looks perfectly healthy from the outside right up until the origin certificate lapses.

## Acceptance criteria

- Every record in the GoDaddy zone export exists in Cloudflare, with mail records set to DNS only.
- A member magic link sent after cutover arrives in a Gmail inbox, and Mailgun logs show DKIM signing intact.
- `cf-cache-status` reports HIT on a repeat anonymous request, and BYPASS for `/ghost/` and for requests carrying `ghost-members-ssr`.
- A signed-in member sees member state, never a cached anonymous page.
- Bump reports average TTFB under 100 ms, down from roughly 650 ms.
- The apex domain 301s to www from the Cloudflare edge, with no dependency on `178.128.137.126`.
- The origin certificate check returns `ssl_verify_result` of 0 and is monitored on a schedule.
