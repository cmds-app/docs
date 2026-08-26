# Request and response formats

The API speaks JSON over HTTPS. Requests send JSON bodies where a body is needed, and responses come back as JSON with camelCase property names. This page covers the conventions that hold across every endpoint - the methods, the shape of a collection, how to select fields, how to read changes incrementally, the status codes, and the error format.

## HTTP methods

The API uses the standard methods, and it keeps verbs out of resource paths - a route names a thing, not an action performed on it.

| Method | Use |
| :--- | :--- |
| `GET` | Read a collection or a single resource |
| `POST` | Run a query that needs a request body, or perform an action such as preparing a dispatch |
| `PUT` | Replace or configure a resource |
| `DELETE` | Remove or unconfigure a resource |

Two conventions are worth knowing. A `POST` that queries a collection carries a `/search` suffix (for example `certification/tickets/search`), which leaves a bare `POST` to a collection free to mean "create" for as long as this API lives. A report is requested with `POST` and a `?format=` parameter rather than a `/search` suffix, because choosing a format commissions an artifact rather than filtering a set.

## Request bodies

Send a request body as JSON with `Content-Type: application/json`. Property names may be camelCase; where a request names fields to include, the match is case-insensitive, so either camelCase or PascalCase works.

Also send:

- `Authorization: Bearer <secret>` or `X-Api-Key: <key>` to authenticate (see [Authentication](authentication.md)).
- `X-Tenant: <organization-handle>` to name your organization, unless your credential already carries it.
- `Accept: application/json` (assumed when absent).

## Response bodies

A response body is JSON with camelCase property names.

**A collection returns a plain JSON array.** Not an envelope, not a file attachment - the array is the whole response. A projected collection omits any property whose value is null, so a field that is absent from a row is null rather than an error.

**A single resource returns a JSON object.** For example, `directory/tenants/{tenant}` answers with one object rather than an array, because a caller looks up a specific organization by id.

There is no wrapping metadata object, no `data` key, and no status field inside the body - the HTTP status carries that.

## Selecting fields

Pass `filter.includes` to restrict a collection to the columns you want, in the order you want them:

```
filter.includes=personId,firstName,lastName,email
```

Matching is case-insensitive. The order you list is the order you get. If none of the names match a real column - usually a typo - the response is an array of empty objects rather than every column, so the mistake fails loudly instead of quietly shipping a far larger payload than you asked for.

## Reading changes incrementally

**There is no paging.** A collection endpoint returns the entire collection. That is what a caller building a mirror wants, and it is what every caller does today. Know what it means at scale: against production data, `directory/members` returns roughly 111,000 rows and `directory/affiliations` roughly 239,000.

The pattern is to mirror once, then read only what has moved since. Pass `lastChangeTimeSince` as an inclusive lower bound on a row's last change time:

```
lastChangeTimeSince=2026-08-01T00:00:00Z
```

Hold your mirror, record the newest change time you have seen, and bound the next read with it rather than downloading the whole collection again.

## Reports and file formats

The compliance reporting endpoint chooses its rendering with a `?format=` query parameter. The filters stay in the request body and the format stays in the URL, so you can change how the answer arrives without touching what you asked for.

| Format | Answer |
| :--- | :--- |
| `json` | The rows, as a JSON array. The default when `format` is omitted |
| `csv` | A `text/csv` attachment, one row per member per measurement |
| `xlsx`, `pdf` | `501 Not Implemented` until a renderer exists - named rather than rejected, because they are intended |
| anything else | `400 Bad Request`, naming the formats that are available |

The CSV leads with a UTF-8 byte order mark so a spreadsheet reads accented names correctly, and any field starting with `=`, `+`, `-`, or `@` is quote-prefixed so a spreadsheet does not treat caller-supplied data as a formula.

## Status codes

| Code | Meaning |
| :--- | :--- |
| `200 OK` | The request succeeded and the body carries the result |
| `204 No Content` | The request succeeded and there is no body (for example, a `DELETE`) |
| `400 Bad Request` | The request is malformed, unbounded, or names an unknown tenant or report format |
| `401 Unauthorized` | No valid credential, or no `X-Tenant` header where one is required |
| `403 Forbidden` | Authenticated, but not entitled - not a member of the tenant, not an operator, or lacking report access |
| `404 Not Found` | The resource does not exist, or you may not see it (a single-resource read you are not entitled to answers `404`, not `403`, so its existence is not revealed) |
| `409 Conflict` | The request collides with current state - for example, preparing a dispatch while one is already waiting |
| `501 Not Implemented` | A named but unbuilt capability, such as a report format without a renderer |
| `503 Service Unavailable` | A dependency the endpoint needs is not available in this deployment |

## Errors

Error responses follow [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) - the `application/problem+json` format. The body carries a human-readable summary and, on some errors, a machine-readable discriminator:

```json
{
    "type": "https://httpstatuses.io/400",
    "title": "Unknown tenant.",
    "status": 400,
    "detail": "'acme' is not a registered tenant.",
    "code": "unknown-tenant"
}
```

| Field | Description |
| :--- | :--- |
| `type` | A URI identifying the problem type |
| `title` | A short, human-readable summary of the problem |
| `status` | The HTTP status code, repeated in the body |
| `detail` | A human-readable explanation specific to this occurrence |
| `instance` | A URI for this specific occurrence, when present |
| `code` | A stable, machine-readable discriminator on the errors that carry one (for example `unknown-tenant`, `no-tenant-access`) |

Match on `status` and `code` rather than on the text of `title` or `detail`, which may be reworded.

## Headers

| Header | Direction | Purpose |
| :--- | :--- | :--- |
| `Authorization` | Request | Bearer credential (`Bearer vsk_...`) |
| `X-Api-Key` | Request | Shared service key, or a personal secret |
| `X-Tenant` | Request | The organization handle, unless the credential carries it |
| `Content-Type` | Request, response | `application/json` for JSON bodies; `text/csv` for a CSV report |
| `Accept` | Request | `application/json`, assumed when absent |
