# Request and response formats

The API speaks JSON over HTTPS. Requests send JSON bodies where a body is needed, and responses come back as JSON with camelCase property names. This page covers the conventions that hold across every endpoint - the methods, the shape of a collection, how to select fields, how to read changes incrementally, the status codes, and the error format.

## HTTP methods

The API uses the standard methods. A read names a thing, not an action performed on it; an action that is not a plain create, replace, or delete is a `POST` to a named step on the resource (for example `notification/dispatches/{dispatchId}/approve`).

| Method | Use |
| :--- | :--- |
| `GET` | Read a collection or a single resource |
| `POST` | Run a query that needs a request body, or perform an action such as preparing a dispatch |
| `PUT` | Replace or configure a resource |
| `DELETE` | Remove or unconfigure a resource |

Two conventions are worth knowing. A `POST` that queries a collection carries a `/search` suffix (for example `certification/tickets/search`), which leaves a bare `POST` to a collection free to mean "create" for as long as this API lives. A report chooses its rendering with a `?format=` parameter rather than a `/search` suffix, because choosing a format commissions an artifact rather than filtering a set. Most reports are a `GET`; `reporting/compliance-summary` is a `POST`, because its filters are too large for a query string.

## Request bodies

Send a request body as JSON with `Content-Type: application/json`. Property names may be camelCase; where a request names fields to include, the match is case-insensitive, so either camelCase or PascalCase works.

Also send:

- `Authorization: Bearer <secret>` or `X-Api-Key: <key>` to authenticate (see [Authentication](authentication.md)).
- `X-Company: <organization-handle>` to name your organization, unless your credential already carries it.
- `Accept: application/json` (assumed when absent).

## Response bodies

A response body is JSON with camelCase property names.

**A directory collection returns a plain JSON array.** The `directory/*` collections (`directory/accounts`, `directory/members`, `directory/affiliations`, and so on) return no envelope and no file attachment - the array is the whole response. A projected collection omits any property whose value is null, so a field that is absent from a row is null rather than an error.

**A search collection returns one page in an envelope.** The search collections - `certification/plans`, `certification/assignments`, `certification/achievements`, `certification/tickets`, `competency/competencies`, `competency/validations`, `competency/profiles`, `competency/designations`, `training/courses`, and `training/enrolments` - return an object with four properties:

```json
{
    "items": [ ... ],
    "total": 1342,
    "page": 1,
    "pageSize": 25
}
```

`items` holds the rows on this page and `total` counts the rows across every page. Ask for a page with the `page` (1-based) and `pageSize` query parameters. `pageSize` defaults to 25 and is capped at 200. An out-of-range value is corrected rather than rejected: a page below 1 reads as the first page, a page size below 1 reads as 25, and a page size above 200 reads as 200.

A search collection can also be ordered with `sort` (the property to order by; each collection documents its own keys) and `direction` (`desc` for descending; anything else is ascending).

**A single resource returns a JSON object.** For example, `directory/companies/{company}` answers with one object rather than an array, because a caller looks up a specific organization by id.

Apart from the search envelope, there is no wrapping metadata object, no `data` key, and no status field inside the body - the HTTP status carries that.

## Selecting fields

Pass `filter.includes` to restrict a collection to the columns you want, in the order you want them:

```
filter.includes=personId,firstName,lastName,email
```

Matching is case-insensitive. The order you list is the order you get. If none of the names match a real column - usually a typo - the response is an array of empty objects rather than every column, so the mistake fails loudly instead of quietly shipping a far larger payload than you asked for.

## Reading changes incrementally

**Directory collections are not paged.** A `directory/*` endpoint returns the entire collection. That is what a caller building a mirror wants. Know what it means at scale: against production data, `directory/members` returns roughly 111,000 rows and `directory/affiliations` roughly 239,000.

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
| `csv` | A `text/csv` attachment, one row per member per department per measurement |
| `xlsx`, `pdf` | `501 Not Implemented` until a renderer exists - named rather than rejected, because they are intended |
| anything else | `400 Bad Request`, naming the formats that are available |

The CSV leads with a UTF-8 byte order mark so a spreadsheet reads accented names correctly, and any field starting with `=`, `+`, `-`, or `@` is quote-prefixed so a spreadsheet does not treat caller-supplied data as a formula.

## Status codes

| Code | Meaning |
| :--- | :--- |
| `200 OK` | The request succeeded and the body carries the result |
| `204 No Content` | The request succeeded and there is no body (for example, a `DELETE`) |
| `400 Bad Request` | The request is malformed or unbounded, names an unknown organization or report format, or lacks an `X-Company` header where one is required |
| `401 Unauthorized` | No valid credential |
| `403 Forbidden` | Authenticated, but not entitled - not a member of the organization, not an operator, or lacking report access |
| `404 Not Found` | The resource does not exist, or you may not see it (a single-resource read you are not entitled to answers `404`, not `403`, so its existence is not revealed) |
| `409 Conflict` | The request collides with current state - for example, preparing a dispatch while one is already waiting |
| `422 Unprocessable Content` | The request is well formed but cannot be carried out as asked - for example, a notification rule that fails verification |
| `429 Too Many Requests` | You have exceeded a rate limit; see [Rate limits and throttling](rate-limits-and-throttling.md) |
| `501 Not Implemented` | A named but unbuilt capability, such as a report format without a renderer |
| `502 Bad Gateway` | A system the endpoint relays to, such as CMDS V4 or Vimeo, refused or failed the request |
| `503 Service Unavailable` | A dependency the endpoint needs is not available in this deployment |

## Errors

Error responses follow [RFC 9457](https://datatracker.ietf.org/doc/html/rfc9457) (which replaced RFC 7807) - the `application/problem+json` format. The body carries a human-readable summary and, on some errors, a machine-readable discriminator:

```json
{
    "type": "https://httpstatuses.io/400",
    "title": "Unknown company.",
    "status": 400,
    "detail": "'acme' is not a registered company.",
    "code": "unknown-company"
}
```

| Field | Description |
| :--- | :--- |
| `type` | A URI identifying the problem type |
| `title` | A short, human-readable summary of the problem |
| `status` | The HTTP status code, repeated in the body |
| `detail` | A human-readable explanation specific to this occurrence |
| `instance` | A URI for this specific occurrence, when present |
| `code` | A stable, machine-readable discriminator on the errors that carry one (for example `unknown-company`, `no-company-access`) |

Match on `status` and `code` rather than on the text of `title` or `detail`, which may be reworded. The `type` URI varies by error, and some problem bodies also carry a `traceId`.

A few refusals are plain `application/json` rather than problem+json:

- A `401` from the authentication gate carries a `detail` naming what is missing, or a `loginUrl` for a browser session.
- A refusal from an operator-only or service-key-only endpoint is `{ "error": "Operator access required." }` or `{ "error": "Service-key access required." }`.

## Headers

| Header | Direction | Purpose |
| :--- | :--- | :--- |
| `Authorization` | Request | Bearer credential (`Bearer vsk_...`) |
| `X-Api-Key` | Request | Shared service key, or a personal secret |
| `X-Company` | Request | The organization handle, unless the credential carries it |
| `Content-Type` | Request, response | `application/json` for JSON bodies; `text/csv` for a CSV report |
| `Accept` | Request | `application/json`, assumed when absent |
