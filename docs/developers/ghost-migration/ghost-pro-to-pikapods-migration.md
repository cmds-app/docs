# Migrate www.myorientations.com from Ghost(Pro) to Pikapods

Ghost(Pro) charges $31 USD per month for hosting that a Pikapods Ghost pod delivers for about $2.50. The keyeracmds.com migration (2026-07-22) proved the approach end to end: 104 pages, 15 images, 351 newsletter members, and both email pipelines moved with zero content loss in an afternoon. This checklist repeats that migration for www.myorientations.com, including every trap found the first time, in the order that avoids them.

Two facts drive the ordering. First, Ghost's JSON export does not include images, and the storage.ghost.io CDN serving them goes dark the moment the Ghost(Pro) subscription is cancelled - so images are secured first, before anything else. Second, self-hosted Ghost has two separate email paths (SMTP config for transactional, Mailgun API key for newsletters), and both must be proven working before DNS cutover, because failures surface as silent bounces rather than errors.

Supporting scripts live in `scripts/` beside this document (crawl-site.ps1, upload-images.ps1, verify-pod.ps1), parameterized; point their output at a scratch folder such as `tmp/data/<site>/` in the repo you run them from.

## Step 1: secure the images

- [ ] Run `crawl-site.ps1`. It walks the sitemap, downloads every original image to `tmp/data/myorientations-site/content/images/` in Ghost's `YYYY/MM` layout, and writes `crawl-manifest.json`.
- [ ] Review `images_external` in the manifest. Any `storage.ghost.io` entries are Ghost(Pro) CDN copies of site images (the script already collapses their paths and downloads them). Other external hosts (keyeracmds had 5 images hotlinked from cmds.insite.com) survive cancellation but are dependencies worth localizing.
- [ ] Confirm there are no draft posts or unpublished images. The crawl only sees published content. If drafts matter, request a full backup from Ghost(Pro) support before cancelling - it can take them a day or two.

## Step 2: export everything from the old admin

All from the Ghost(Pro) admin, into `tmp/data/myorientations-site/`:

- [ ] **Content JSON.** Settings, Import/Export. The export normalizes image URLs to `__GHOST_URL__` placeholders, so no CDN-URL rewriting is needed.
- [ ] **Members CSV.** Members list, export all. Check for `stripe_customer_id` values - paid members complicate migration (keyeracmds had none; all 351 were free).
- [ ] **Theme zip.** Settings, Design, download.
- [ ] **redirects.yaml and routes.yaml.** Settings, Labs.
- [ ] **Code injection.** Copy header and footer text manually - it is not in any export.
- [ ] Note the newsletter sender settings and any announcement-bar or portal configuration for later comparison.

## Step 3: create the pod and import content

- [ ] Pikapods: Add Pod, Ghost, US region, default resources.
- [ ] Import the content JSON (Settings, Import/Export, Universal import).
- [ ] **Fix slug collisions.** The stock install owns slugs that imported content wants. On keyeracmds the real About page landed on `about-2` while `/about/` served the stock placeholder. Delete the stock About page first, then edit the imported one back to its original slug. Check both Posts and Pages - an "about" that was authored as a post will not appear under Pages.
- [ ] **Fix the author slug.** The import creates a duplicate staff user (`<name>-2`). Deleting the duplicate reassigns its posts to the site owner, which 404s the original author URL. After dedupe, set the surviving profile's slug back to the original (Settings, Staff, profile, Slug field) and confirm post attribution matches the old site.
- [ ] Upload theme zip and activate. Upload routes.yaml and redirects.yaml (Settings, Labs). Paste code injection.
- [ ] Import the members CSV.

## Step 4: upload images

- [ ] Enable SFTP in pod settings, note host/user/password.
- [ ] Run `upload-images.ps1` (needs the Posh-SSH module; installs with `Install-PSResource Posh-SSH -Scope CurrentUser`). It uploads into `content/images/` and HTTP-verifies every file.

## Step 5: email, both pipelines

Ghost sends two kinds of email through two unrelated code paths. Confusing them cost the most debugging time on keyeracmds.

- [ ] **Newsletter (bulk) path.** Ghost admin, Settings, Email newsletter: Mailgun region, sending domain, API key. This covers newsletters only.
- [ ] **Transactional path.** Signup magic links and password resets ignore the API key and need SMTP env vars in the Pikapods Env Vars panel (double underscores are the config separator):

      mail__transport=SMTP
      mail__options__host=smtp.mailgun.org
      mail__options__port=587
      mail__options__secure=false
      mail__options__auth__user=postmaster@<mailgun-sending-domain>
      mail__options__auth__pass=<SMTP password>
      mail__from="Site Name" <noreply@<mailgun-sending-domain>>

- [ ] **Use the sending subdomain in the SMTP username.** keyeracmds failed auth for an hour because the credential belonged to `postmaster@mail.keyeracmds.com` while the env var said `postmaster@keyeracmds.com`. The SMTP password comes from Mailgun's Domain settings, SMTP credentials (reset it there if unknown) - it is a separate secret from the API key, though both use the same hex-with-suffixes format.
- [ ] **Check Mailgun IP access management.** Account Settings, Security. If the allowlist has entries, the pod's outbound IP is not among them and every send fails with `535 Authentication failed` even with correct credentials. Empty the list (empty means disabled, not deny-all) - the pod's outbound IP is not stable enough to allowlist.
- [ ] **Restart the pod explicitly** after env var changes; a save does not always cycle the process.
- [ ] **Test transactional:** attempt a member signup on the pod URL. Expect Gmail to bounce it with a pikapod.net DMARC rejection until DNS cutover - Mailgun's event log (Sending, Logs) distinguishes "Mailgun accepted and receiver bounced" from "auth failed". Accepted-then-DMARC-bounce is the healthy pre-cutover state.
- [ ] **Test newsletter:** create a throwaway draft, Preview, Email tab, Send test email (drafts only - published posts hide the button). Send to an inbox you control; corporate filters (Keyera's gateway) can quarantine or delay the first delivery from a new sender.

## Step 6: de-Ghost the branding

- [ ] **Email badge.** Ghost 6.53's admin UI has no visible toggle for the "Powered by Ghost" email footer badge. Create a custom integration (Settings, Integrations), then flip `show_badge` to false on every newsletter via the Admin API. The keyeracmds session has the working JWT + PUT script.
- [ ] **Site footer.** If the theme renders a `gh-powered-by` div, empty the anchor inside it but keep the div - deleting the whole div breaks the footer grid layout (learned the hard way).

## Step 7: off-site backup

- [ ] Cloudflare R2: create a private bucket (`myorientations-ghost-backup`), then an R2 API token scoped to it with Object Read & Write.
- [ ] Pikapods backup config wants the token's **S3 credentials** - the 32-char Access Key ID and 64-char Secret Access Key shown under "Use the following credentials for S3 clients" - not the Cloudflare token value. Endpoint is `https://<accountid>.r2.cloudflarestorage.com`.
- [ ] Run a first backup and confirm the bucket shows a restic layout (`data/`, `index/`, `keys/`, `snapshots/`, `config`).

## Step 8: DNS cutover and cancellation

- [ ] Lower the TTL on the `www` record ahead of time.
- [ ] Set `www.myorientations.com` in the pod's Domain field first, then flip the CNAME to the pod hostname. Let's Encrypt issuance takes a minute or two after propagation.
- [ ] **If the cert does not appear within a few minutes, restart the pod.** The pod attempts issuance when the domain is saved; if DNS was not pointing at it yet, the attempt fails and sits in a retry backoff. A restart forces a fresh attempt (this unstuck keyeracmds within seconds).
- [ ] **If Pikapods says it cannot verify the domain despite correct DNS, clear the field and retype the domain by hand.** A pasted value can carry an invisible trailing character that survives visual inspection; on myorientations this blocked verification for an hour while every resolver on the internet returned the correct CNAME.
- [ ] Run `verify-pod.ps1` against `https://www.myorientations.com`: every page, title, and image compared to the crawl manifest, plus RSS and sitemap.
- [ ] Retest member signup - the DMARC bounce disappears once the From-domain is real. Confirm the magic-link email lands in a Gmail inbox.
- [ ] Confirm bare `myorientations.com` still redirects to `www`. Ghost(Pro)'s edge may be providing that redirect today, and it dies at cancellation.
- [ ] Set the newsletter sender address to the real domain if it still shows a placeholder.
- [ ] Cancel Ghost(Pro) only after all of the above pass. The overlap costs about a dollar a day.
- [ ] Cleanup: delete the signup-test member and the newsletter-test draft.

## Acceptance criteria

- verify-pod.ps1 reports zero missing pages, zero title diffs, zero broken images, zero storage.ghost.io references on the final domain.
- A member signup from a Gmail address receives its magic-link email.
- A newsletter test email arrives with no "Powered by Ghost" badge.
- The R2 bucket contains at least one restic snapshot.
- Bare-domain and www URLs both resolve to the pod over HTTPS.
- Ghost(Pro) subscription cancelled; hosting cost drops from $31 to roughly $2.50 per month.

## After cutover: restore the CDN

Ghost(Pro) served pages from Fastly, and cancelling it removes that edge cache along with the hosting. Expect time-to-first-byte to rise by roughly a factor of ten - keyeracmds went from about 65 ms to about 650 ms. See [Put Cloudflare in front of a Pikapods Ghost pod](cloudflare-cache-in-front-of-pikapods.md) for the fix.
