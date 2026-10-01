# Authentication

Every request to the API is authenticated. There are three ways to do it, and which one you reach for depends on what is making the call:

- A **personal API secret** is the credential for an integration or script that acts as you. This is the one most developers want.
- A **shared service key** is for a trusted server-to-server caller that acts as the platform rather than as a person.
- A **session cookie** is for a browser-based integration where an already-signed-in user is making the calls.

A credential carries the same access its owner has in the user interface. Treat it as you would a password.

## Personal API secrets

A personal API secret is a single credential you generate on your own account and send with each request. It looks like this:

```
vsk_live_your_secret_here
```

The shape is `vsk_<environment>_<random>`, after the pattern Stripe and Cloudflare use for keys. The `vsk_` prefix marks it as a CMDS secret, and the environment segment means a leaked key announces which environment it opens - a `vsk_test_` key cannot be mistaken for a `vsk_live_` one.

### Enabling access

Access is a grant, not self-service. Before you can generate a working secret, an operator has to enable API access for your account on the **Security > Accounts** page. Two grants are kept apart:

- **API access.** Whether your account may hold and use a secret at all.
- **Report access.** Whether that secret may reach the reporting surface (`reporting/compliance-summary`, `reporting/monthly-statistics`, and `reporting/competency-validations`), which reads a whole organization's standing and is gated more tightly than the rest of the API.

Granting report access turns API access on with it, since a secret that may report but may not call would be refused on every request.

Both are re-checked on every request. If an operator revokes either one, your secret stops working on its next call rather than at some expiry.

### Generating your secret

Once API access is enabled, sign in to the application for your organization, open your account page, and generate a secret. It is shown to you **once**, at the moment you create it. The server stores only a hash of it and can never display it again, so copy it somewhere safe before you leave the page.

Generating a new secret replaces any existing one. There is exactly one personal secret per account.

!!! warning
    Keep your API secret secure. Do not share it in emails, chat messages, client-side code, or publicly accessible repositories.

    If a secret is exposed, revoke it and generate a new one. Because every request re-hashes and re-reads the presented value, a revoked secret stops working immediately.

### Sending your secret

Send the secret as a bearer token in the `Authorization` header. This is the canonical scheme ([RFC 6750](https://datatracker.ietf.org/doc/html/rfc6750)), the same way GitHub and Stripe take a key:

```
Authorization: Bearer vsk_live_your_secret_here
```

The `X-Api-Key` header is also accepted and carries the same value:

```
X-Api-Key: vsk_live_your_secret_here
```

A personal secret carries its own organization - the one you generated it under - so you do **not** send the `X-Company` header with it. The secret names the organization for you.

#### curl (Linux / macOS)

```bash
curl "https://api.cmds.app/me/client-secret" \
    -H "Authorization: Bearer vsk_live_your_secret_here"
```

#### PowerShell (Windows)

```powershell
$secret = "vsk_live_your_secret_here"

curl.exe "https://api.cmds.app/me/client-secret" `
    -H "Authorization: Bearer $secret"
```

### Managing your secret

Three endpoints manage the secret on your account:

| Method | Endpoint | What it does |
| :--- | :--- | :--- |
| `GET` | `me/client-secret` | Reports whether a secret exists, its short prefix, and when it was generated and last used. Never the secret itself |
| `POST` | `me/client-secret` | Generates a secret and returns it once, replacing any existing one |
| `DELETE` | `me/client-secret` | Revokes the secret. The value stops authenticating on the next call |

These endpoints act on the account making the request, so you typically manage a secret from a signed-in browser session on your account page (see [Session authentication](#session-authentication)).

## Shared service key

The shared service key is a single secret configured for the environment, used by trusted server-to-server callers that cannot carry a user's session - for example, the platform's own command-line tool running scheduled jobs. Send it in the `X-Api-Key` header:

```
X-Api-Key: <shared-service-key>
```

A caller holding this key is not a person and is not scoped to one organization. It is the platform's own key, issued by an administrator rather than generated on an account, and it is not the credential a typical integration uses. If you are building an integration that acts as a user, use a personal API secret instead.

## Session authentication

Most API endpoints also accept a session cookie. This suits a browser-based interface served from a `cmds.app` address the platform trusts: the cookie is scoped to `.cmds.app`, and the API accepts credentialed browser requests only from the origins configured for each environment. A front end on your own domain cannot use the session; give it a personal API secret held on your server instead.

A session is established by signing in, either through single sign-on or with an email and password, and the server mints a signed cookie. The cookie is built with several protections:

- The `Secure` flag ensures it travels only over HTTPS, preventing interception in transit.
- The `HttpOnly` attribute keeps client-side scripts from reading it, mitigating cross-site scripting (XSS).
- It expires 8 hours after you sign in.
- The `Domain` (`.cmds.app`) and `Path` (`/`) attributes limit where the browser sends it.
- The value is a signed [JSON Web Token](https://datatracker.ietf.org/doc/html/rfc7519), so it cannot be forged or altered. It is not encrypted: anyone holding the cookie can decode and read its claims, so treat it like any other credential and never log it or pass it in a URL.

A cookie session records the organization you signed in to, but many endpoints read the organization from the request itself and answer `400 Company required` without it. Send the `X-Company` header with each request to say which organization you are acting for; it can name any organization your account belongs to (see below).

## Naming your organization

API URLs carry no organization segment, so most requests name the organization in a header:

- A **personal API secret** carries its own organization. Send no `X-Company` header.
- A **session cookie** records where you signed in, but send `X-Company: <your-organization-handle>` with each request anyway.
- A **shared service key** is not scoped to an organization. Where an endpoint supports it, it names one with the `companyId` query parameter, which only operators and the service key may use.

The header value is your organization's handle. It must name a registered organization, or the request is rejected:

| Response | Meaning |
| :--- | :--- |
| `400 Unknown company` | The `X-Company` value does not name a registered organization |
| `403 No access to this company` | Your account is authenticated but is not a member of the named organization |

## What a credential can do

Authorization today is authenticate-only: a valid credential can call any endpoint that its organization scope allows. There is not yet a per-endpoint permission matrix.

Two checks sit on top of that:

- **Operator endpoints.** Whole administrative modules require an operator account and answer `403` otherwise: `notification/*`, `sync/*`, `quad/*`, `workday/employees`, `support/issues`, `vimeo`, `reporting/video-statistics`, and `diagnostic/about`, among others. A personal secret owned by an operator carries operator rights across every organization, so guard one carefully.
- **Report access.** The three reporting endpoints check the report grant described under [Enabling access](#enabling-access), because they read a whole organization's standing.

Everything else is open to any authenticated caller scoped to the organization. Plan your integration on the assumption that a secret is as capable as the account behind it - which is why the shortest safe lifetime and prompt revocation of a leaked key both matter.
