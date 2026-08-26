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
- **Report access.** Whether that secret may reach the compliance reporting surface, which reads a whole organization's standing and is gated more tightly than the rest of the API.

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

A personal secret carries its own tenant - the organization you generated it under - so you do **not** send the `X-Tenant` header with it. The secret names the organization for you.

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

The shared service key is a single secret configured for the environment, used by trusted server-to-server callers that cannot carry a user's session - for example, an external system registering itself with the platform. Send it in the `X-Api-Key` header:

```
X-Api-Key: <shared-service-key>
```

A caller holding this key is not a person and is not scoped to one organization. It is the platform's own key, issued by an administrator rather than generated on an account, and it is not the credential a typical integration uses. If you are building an integration that acts as a user, use a personal API secret instead.

## Session authentication

Most API endpoints also accept a session cookie. This suits a browser-based integration - for example, if you run the platform in [headless mode](https://en.wikipedia.org/wiki/Headless_software) and build your own interface with a library such as [React](https://react.dev/), your authenticated users' requests can carry the cookie the browser already sends.

A session is established by signing in, either through single sign-on or with an email and password, and the server mints a signed cookie. The cookie is built with several protections:

- The `Secure` flag ensures it travels only over HTTPS, preventing interception in transit.
- The `HttpOnly` attribute keeps client-side scripts from reading it, mitigating cross-site scripting (XSS).
- The `SameSite` attribute limits it to the contexts that should send it, mitigating cross-site request forgery (CSRF).
- An expiration date bounds its lifetime.
- Domain and path restrictions limit where it is sent.
- The value is signed and encrypted, so it cannot be forged or read.

A cookie session does not name your organization on its own. Send the `X-Tenant` header with each request to say which organization you are acting for (see below).

## Naming your organization

API URLs carry no tenant segment, so most requests name the organization in a header:

- A **personal API secret** carries its own organization. Send no `X-Tenant` header.
- A **session cookie** does not. Send `X-Tenant: <your-organization-handle>` with each request.
- A **shared service key** is not scoped to an organization; it names one per request where the endpoint needs it.

The header value is your organization's handle. It must name a registered organization, or the request is rejected:

| Response | Meaning |
| :--- | :--- |
| `400 Unknown tenant` | The `X-Tenant` value does not name a registered organization |
| `403 No access to this tenant` | Your account is authenticated but is not a member of the named organization |

## What a credential can do

Authorization today is authenticate-only: a valid credential can call any endpoint that its organization scope allows. There is not yet a per-endpoint permission matrix.

Two checks sit on top of that:

- **Operator endpoints.** A small set of administrative endpoints require an operator account and answer `403` otherwise.
- **Report access.** The compliance reporting surface checks the report grant described under [Enabling access](#enabling-access), because it reads a whole organization's standing.

Everything else is open to any authenticated caller scoped to the organization. Plan your integration on the assumption that a secret is as capable as the account behind it - which is why the shortest safe lifetime and prompt revocation of a leaked key both matter.
