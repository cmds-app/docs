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

That apex redirector is shared, so it can only be retired after every site behind it has moved to Cloudflare. keyeracmds.com moved on 2026-07-29, which leaves myorientations.com as the last site behind it - once that one is done, the droplet can be decommissioned.

One thing not to be alarmed by in the meantime: the droplet holds a separate Let's Encrypt certificate per apex, and each one stops renewing as soon as that apex points at Cloudflare. HTTP-01 validation never reaches the box again. The keyeracmds certificate on it expires 2026-08-29 and nothing uses it, so the renewal failures in Caddy's log are expected. Drop the hostname from the Caddyfile if you would rather not see them.

## Step 1: inventory the existing zone

- [ ] Export the zone file from GoDaddy DNS management. This is both your diff target for step 2 and your rollback.
- [ ] Identify every mail record. On keyeracmds that is: `mail` MX to `mxa`/`mxb.mailgun.org`, `mail` TXT SPF, the DKIM key at `pic._domainkey.mail`, the tracking CNAME `email.mail` to `mailgun.org`, apex SPF, and `_dmarc` TXT with three `rua` targets. **Mailgun assigns a per-domain DKIM selector**, so do not assume `pic` or `k1` - read it off the export or off the Mailgun domain page.
- [ ] Note any verification TXT records. keyeracmds carries an `ahrefs-site-verification_...` value that means nothing to you today and breaks somebody's tooling if it disappears.
- [ ] **Resolve every A record and ask what it is.** A zone accumulates hostnames pointing at infrastructure that has no business serving this domain. keyeracmds carried a wildcard and four subdomains aimed at InSite production and sandbox servers. Migration is the right moment to drop them, but decide deliberately rather than copying them forward by reflex.
- [ ] For anything you plan to delete, check what depends on it first. A wildcard hides its own dependents - every hostname resolves, so the zone cannot tell you which ones are used. IIS bindings, access logs, and the certificate check in the last section of this runbook are your evidence.

Miss a mail record and nothing fails loudly. Newsletters keep sending and quietly start failing DMARC at the receiver, which you will discover from open rates a week later.

## Step 2: add the site to Cloudflare

- [ ] Add site, Free plan. Cloudflare scans the existing zone and imports what it finds.
- [ ] **Diff the imported records against your GoDaddy export, one by one.** The scanner is reliable for common types and misses long TXT values and some subdomain records. This is the single highest-risk step in the runbook and it is entirely mechanical.

On keyeracmds the scan imported 18 of 26 records. It dropped four A records, two CNAMEs, and two TXT records, one of which was the Mailgun DKIM key at `pic._domainkey.mail`. Both categories it missed are predictable: records nested two labels deep under a subdomain, and TXT values split across multiple strings.

**Split TXT values need care when you re-enter them.** A single TXT character-string caps at 255 bytes, so a 2048-bit DKIM key arrives in the export as two quoted chunks:

    mx._domainkey  IN  TXT  "k=rsa; p=MIIBIjANBg...jtKgoi" "XreklOdyy1X5...QIDAQAB"

Resolvers concatenate those with **no separator**. Paste them into Cloudflare as one continuous value with nothing between `jtKgoi` and `Xrekl` - Cloudflare re-splits anything over 255 bytes itself when it serves the record. Insert a space at the join and DKIM verification fails silently, which is the same failure mode as omitting the record entirely. Where the scanner did import a split record, open it and confirm the value survived rather than assuming.

## Step 3: set proxy flags and the apex redirect

The orange-cloud toggle decides whether a record is proxied through Cloudflare or served as plain DNS. Getting this wrong on mail records breaks email; getting it wrong on `www` means you did all this work for nothing.

- [ ] `www` CNAME to the pod hostname: **proxied** (orange).
- [ ] Everything under `mail.` and `email.mail.`: **DNS only** (grey).
- [ ] Delete the apex A record pointing at `178.128.137.126`. Replace it with a proxied dummy - an `A` record to `192.0.2.1` (the RFC 5737 documentation address), orange. The address is never contacted; it exists only so a rule has something to fire on.
- [ ] Rules, Redirect Rules: when hostname equals the apex, redirect to www carrying the path, status 301, preserve query string.

Pick **Dynamic**, not Static. Cloudflare's Static type takes a fixed URL and discards the request path, so `keyeracmds.com/about/` would land on the home page. Dynamic builds the target from an expression:

    http.host eq "keyeracmds.com"

    concat("https://www.keyeracmds.com", http.request.uri.path)

Set status 301 and check preserve query string. If you would rather not commit to a permanent redirect while the zone settles, use 302 first and edit it to 301 once verified - browsers cache a 301 hard, and some cache it indefinitely.

**Create the rule in the same sitting as the dummy A record.** Those two checkboxes are one change, not two. `192.0.2.1` is an address nothing answers on, so the moment Cloudflare starts serving the apex without a redirect rule to intercept it first, every apex request becomes a `522 Connection timed out`. While the old droplet A record is still cached you will not notice, which is exactly what makes it easy to leave half-done and walk away.

The redirect now happens at the edge in single-digit milliseconds instead of crossing the internet to a DigitalOcean droplet and back.

## Step 4: disable the Cloudflare defaults that break Ghost

Do this before the nameserver flip, so the settings are already correct the moment traffic arrives.

- [ ] **Rocket Loader: off.** It defers and rewrites script loading, which breaks Ghost Portal - the signup and sign-in modal.
- [ ] **Bot Fight Mode: off.** It issues challenges to non-browser clients, which includes Ghost's own Admin API calls, your webhooks, and every RSS reader subscribed to the site.
- [ ] **Email Obfuscation: off.** It injects a script into your HTML to rewrite mailto links. Harmless in theory, an unnecessary variable in a theme you did not write. On current dashboards this is no longer a zone toggle - it lives under Security, Settings, and may only be settable as a Configuration Rule. Do not spend a rule slot on it before checking whether it is doing anything: compare the byte count Cloudflare serves against the origin's `Content-Length`, and look for `data-cfemail` or `/cdn-cgi/scripts` in the HTML. Identical bytes and no injected markup means it is inert on this theme.
- [ ] **SSL/TLS encryption mode: Full (strict).** The pod holds a valid Let's Encrypt certificate for the custom domain, so strict verification passes. Anything weaker leaves the Cloudflare-to-origin hop unauthenticated for no benefit.
- [ ] **Always Use HTTPS: leave off for now.** Enable it in step 6, once Universal SSL reports Active. Turning it on before the edge certificate exists produces redirect loops.

## Step 5: flip the nameservers

Before you touch GoDaddy, verify the zone against Cloudflare's own nameservers. They answer for your zone the moment it is created, while the rest of the world still resolves through GoDaddy, so this costs nothing and catches a bad record while rollback is still free:

    $ns = 'agustin.ns.cloudflare.com'   # your assigned nameserver, from the dashboard

    Resolve-DnsName <domain>            -Type A     -Server $ns -DnsOnly
    Resolve-DnsName www.<domain>        -Type CNAME -Server $ns -DnsOnly
    Resolve-DnsName <domain>            -Type MX    -Server $ns -DnsOnly
    Resolve-DnsName mail.<domain>       -Type MX    -Server $ns -DnsOnly
    Resolve-DnsName <selector>._domainkey.mail.<domain> -Type TXT -Server $ns -DnsOnly | Select-Object -Expand Strings

Each DKIM answer should come back as **two** strings. One means the value was truncated on entry; zero means the record never saved. `-DnsOnly` suppresses LLMNR and NetBIOS fallback so a missing record fails cleanly instead of resolving via something local. A nameserver that answers `REFUSED` is not one of the two assigned to this zone.

- [ ] Verify the zone against Cloudflare's nameservers, as above.
- [ ] At GoDaddy, replace the `*.domaincontrol.com` nameservers with the two Cloudflare nameservers shown in the dashboard.
- [ ] Wait for Cloudflare to report the zone Active. Usually minutes. Universal SSL issuance is separate and can take up to 24 hours, though it is typically fast.

## Step 6: verify proxied, before caching anything

Resist the urge to add cache rules yet. Confirm the plain proxy path is intact first, so that if something breaks later you know the cache rules caused it.

- [ ] Confirm traffic is proxied:

      curl -sSI https://www.<domain>/ | grep -iE 'server|cf-ray|cf-cache-status'

  Expect `server: cloudflare` and a `cf-ray` header.

**Do not wait on your own resolver to see this.** Public DNS caches hold the old records until their TTLs expire, and your ISP's resolver may hold them a good deal longer than the TTL suggests. Force the edge directly instead:

    curl -sSI --resolve www.<domain>:443:<any-cloudflare-anycast-ip> https://www.<domain>/

Any Cloudflare edge address works, since routing is by SNI and Host header. Take one from `Resolve-DnsName www.<domain> -Server 1.1.1.1` once a public resolver has updated. This same trick verifies the redirect rule and the cache rules before propagation reaches you, which turns an hour of waiting into a working feedback loop.

Two Windows gotchas, both of which cost time on keyeracmds. `ipconfig /flushdns` clears the local cache but does nothing about a stale entry upstream at the ISP. And `Set-DnsClientServerAddress -ServerAddresses 1.1.1.1,1.0.0.1` sets **only** the IPv4 family - if the adapter also has IPv6 DNS servers, Windows keeps using those and your change has no effect. Set both families in one call:

    Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' `
      -ServerAddresses ('1.1.1.1','1.0.0.1','2606:4700:4700::1111','2606:4700:4700::1001')

Reset with `-ResetServerAddresses` when you are done.

- [ ] Click through in a browser: a post page, an image, the subscribe form (expect a 201), `/ghost/` admin sign-in, and the apex redirect.
- [ ] Send yourself a member **signup** link, not a sign-in link, and confirm it arrives.
- [ ] Now enable **Always Use HTTPS**.

**Use the subscribe form, not sign in.** Ghost refuses to send a sign-in link to an address that is not already a member, and returns success either way so that nobody can enumerate your membership list by watching responses. No error, no email, and it looks exactly like broken mail. If you test with sign in on an address that was never a member, you will spend an hour debugging DNS that is working correctly.

**One arriving email does not clear the whole mail path.** Ghost sends staff mail - password resets, invites - through its transactional transport, and member mail through the Mailgun configuration in Admin. Those can use different domains and different DKIM selectors, so a working staff password reset proves nothing about the record the Cloudflare scanner most likely dropped. Verify against the received message rather than its arrival: open the headers and confirm `dkim=pass` with `header.s=` matching the selector you re-entered, `spf=pass`, and `dmarc=pass`.

Mail that authenticates cleanly can still land in spam - a domain that changed sending infrastructure recently has no reputation to draw on, and `p=none` gives receivers no enforcement signal to lean on. That is a reputation problem, not a DNS one, and nothing in this runbook fixes it. Do not go re-checking records over it once the headers show all three passing.

## Step 7: add the cache rules

Caching, Cache Rules. You'd expect the first matching rule to win, the way a firewall ACL works. It doesn't. Every matching rule executes in order, and for a setting two rules both touch, **the last one applied wins**. Put a bypass rule above a caching rule whose expression also matches, and the caching rule silently overrides it.

That is not a theoretical concern. On keyeracmds, rule 2 matched on hostname alone, so it matched every request including `/ghost/` and every request carrying a member cookie. With the bypass sitting first and looking correct in the dashboard, member-specific HTML was eligible for the edge cache. Step 8 caught it, but only because the checks test the bypass paths explicitly.

So do not rely on ordering at all. **Make the two expressions mutually exclusive**, and the precedence question stops mattering.

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

**Rule 2, "Cache HTML at edge"** - expression, which is rule 1's expression negated and anded onto the hostname:

    http.host eq "www.<domain>"
    and not (
      starts_with(http.request.uri.path, "/ghost/")
      or starts_with(http.request.uri.path, "/members/")
      or starts_with(http.request.uri.path, "/r/")
      or starts_with(http.request.uri.path, "/p/")
      or starts_with(http.request.uri.path, "/webmentions/")
      or starts_with(http.request.uri.path, "/.well-known/")
      or http.cookie contains "ghost-members-ssr"
    )

Settings:

- Cache eligibility: **Eligible for cache**
- Edge TTL: **Ignore cache-control header and use this TTL**, `3600`
- Browser TTL: **Respect origin**

Edge TTL is a free-form field in seconds, not a list of preset durations, so an hour is `3600`.

That Edge TTL override is the entire fix. Without it Cloudflare obeys the pod's `max-age=0`, caches nothing, and response times do not move. Browser TTL stays at origin deliberately: visitors keep revalidating, so a purge is visible immediately rather than waiting out a stale copy in somebody's browser.

## Step 8: verify caching behavior

Four checks, all of which must pass. If any one disagrees, a rule is wrong.

    curl -sSI https://www.<domain>/ | grep -i cf-cache-status                 # MISS on first request
    curl -sSI https://www.<domain>/ | grep -i cf-cache-status                 # HIT on second
    curl -sSI -b 'ghost-members-ssr=x' https://www.<domain>/ \
      | grep -i cf-cache-status                                               # not cached
    curl -sSI https://www.<domain>/ghost/ | grep -i cf-cache-status           # not cached

Expect `DYNAMIC` on the last two, not `BYPASS`. Both mean the response did not come from cache, and either one passes. The distinction is worth knowing anyway: `BYPASS` says a rule ordered Cloudflare not to cache, while `DYNAMIC` says Cloudflare decided against caching on its own, usually because the origin sent `max-age=0`. Ghost sends exactly that, so a working bypass rule and no bypass rule at all produce the same label on HTML.

Which means these four checks cannot tell you whether rule 1 is firing. To prove that, test something Cloudflare **would** cache - any image under `/content/images/` - with and without the member cookie:

    curl -sSI https://www.<domain>/content/images/<any-image>  | grep -i cf-cache-status   # HIT once warm
    curl -sSI -b 'ghost-members-ssr=x' \
      https://www.<domain>/content/images/<any-image>          | grep -i cf-cache-status   # DYNAMIC

Same URL, cached copy sitting at the edge, and the cookie suppresses the hit. That is rule 1 doing its job, and nothing else explains it.

- [ ] All four match.
- [ ] Sign in as a member in a browser and confirm you see member state, not a cached anonymous page.
- [ ] Check the Bump monitor. Cache hits should land in the 20-50 ms range, better than the 65 ms Ghost(Pro) delivered. Misses stay around 650 ms, which is now a rare event rather than every pageview.

**Measure the right number.** A one-shot `curl` opens a fresh TCP connection and TLS session every time, and `time_starttransfer` includes both. On keyeracmds that read 95 ms against a 25 ms TCP connect and a 60 ms TLS handshake, so the actual served-from-cache time was about 35 ms. Subtract `time_appconnect` from `time_starttransfer` to see what the edge is really doing, or you will read a healthy result as a failure:

    curl -sS -o /dev/null -w 'tcp=%{time_connect} tls=%{time_appconnect} ttfb=%{time_starttransfer}\n' \
      https://www.<domain>/

Before the cache rules, the same measurement on keyeracmds was 410-634 ms.

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

## Who else holds a certificate for this domain?

Before you move nameservers, ask a question the runbook above does not: is anybody outside this project issuing certificates for hostnames under this domain? A nameserver move revokes their ability to answer ACME challenges, and the damage lands on systems you were not touching.

On keyeracmds this was live. Four subdomains - `demo`, `dev`, `sandbox`, `test` - pointed at an InSite server that returned 404 on all of them, so they looked like dead records worth deleting. But the TLS handshake succeeded, and reading the certificate showed why:

    echo | openssl s_client -connect demo.keyeracmds.com:443 -servername demo.keyeracmds.com 2>/dev/null \
      | openssl x509 -noout -subject -issuer -dates -ext subjectAltName

The answer was a single Let's Encrypt certificate, `CN=*.shiftiq.com`, carrying eleven domains and their wildcards in its SAN list: shiftiq.com, shiftiq.app, insite.com, insitemessages.com, cmds.app, crosstrade.ca, keyeracmds.com, ltcbc.ca, nbfast.ca, skillscheck.ca, skillspassport.com. Validation was DNS-01, which is what the two `_acme-challenge` TXT records in the zone export were for.

Here's the challenge. Because those names share one certificate order, a validation failure on any single name fails the whole order. Moving keyeracmds.com to Cloudflare means InSite's ACME client can no longer write `_acme-challenge` records into that zone, its next renewal fails, and the certificate protecting shiftiq.com and insite.com expires with it. The site you migrated is fine. The blast radius is somewhere else entirely, roughly 60 days later, and nothing in either system connects the two events.

- [ ] Read the certificate on every hostname in the zone you are about to move, not just the one you care about. A 404 tells you nothing; the SAN list tells you everything.
- [ ] For any name that appears on a certificate issued by a system outside this project, get that name removed from the certificate request and reissued **before** the nameserver flip.
- [ ] Do not solve it by handing the other system credentials for your new DNS provider. That points the dependency backwards and leaves you owning their renewals.
- [ ] Note the `_acme-challenge` TXT records in the export for what they are: evidence of a DNS-01 client you may not control. Leaving them behind is correct once the name is off the certificate, and carrying them over accomplishes nothing, since the tokens are single-use.

## Acceptance criteria

- Every record in the GoDaddy zone export either exists in Cloudflare or was dropped deliberately, with a reason you can state. Mail records are set to DNS only.
- No hostname in the moved zone appears on a certificate issued by a system that can no longer answer its ACME challenges.
- A member magic link sent after cutover arrives in a Gmail inbox, and Mailgun logs show DKIM signing intact.
- `cf-cache-status` reports HIT on a repeat anonymous request, and something other than HIT for `/ghost/` and for requests carrying `ghost-members-ssr`.
- A cached image returns HIT anonymously and DYNAMIC with a `ghost-members-ssr` cookie, proving the bypass rule fires rather than the origin's `max-age=0` masking its absence.
- A signed-in member sees member state, never a cached anonymous page.
- Bump reports average TTFB under 100 ms, down from roughly 650 ms.
- The apex domain 301s to www from the Cloudflare edge, with no dependency on `178.128.137.126`.
- The origin certificate check returns `ssl_verify_result` of 0 and is monitored on a schedule.
