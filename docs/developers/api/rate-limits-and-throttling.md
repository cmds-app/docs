# Rate limits and throttling

The API caps how fast a single credential can call it. The point is fairness: one integration stuck in a loop, or one client hammering the heaviest endpoint, should not slow the API down for everyone else. In normal use you will not notice the limits - they are set well above what ordinary client code does - but your integration should still be ready for the moment it crosses one.

## How the limits work

Each limit is a **fixed window**: a maximum number of requests within a rolling span of time, counted per credential. Your personal API secret has its own count; another developer's secret has its own. When the count for the current window is used up, further requests are rejected until the window resets.

Requests are counted separately per surface. Your everyday reads and your compliance reports draw on different buckets, so a burst of reports cannot exhaust the allowance for the rest of the API, and neither starves the other.

## The limits

| Surface | What it covers | Limit |
| :--- | :--- | :--- |
| Default | Every authenticated endpoint that is not one of the below | 300 requests / minute |
| Reports | `reporting/compliance-summary` | 30 requests / minute |
| Sign-in | `auth/login`, `auth/ticket` | 10 requests / 5 minutes, per IP address |

The report surface is tighter because a single compliance request reads a whole organization's standing and can return a multi-megabyte body. Sign-in is capped per IP address rather than per credential, since a caller signing in does not have one yet; the tighter count blunts brute-force attempts.

These are the starting values and may be tuned over time. Treat the `Retry-After` header on a rejection, not a hardcoded number, as the authority on how long to wait.

## When you hit a limit

A rejected request returns `429 Too Many Requests` with a `Retry-After` header giving the number of seconds until the window resets. The body is the same `application/problem+json` shape as every other error, with a `code` of `rate-limited`:

```
HTTP/1.1 429 Too Many Requests
Retry-After: 42
Content-Type: application/problem+json
```

```json
{
    "type": "https://httpstatuses.io/429",
    "title": "Too many requests.",
    "status": 429,
    "detail": "The rate limit for your credential has been exceeded. Retry after the interval named in the Retry-After header.",
    "code": "rate-limited"
}
```

## Staying within the limits

- **Honor `Retry-After`.** When you get a `429`, wait the number of seconds it names before retrying. It is the exact time until your window resets.
- **Back off on repeated rejections.** If a retry is also rejected, increase the wait between attempts (exponential backoff) rather than retrying in a tight loop.
- **Read deltas, not the whole world.** The heaviest cost is re-downloading a full collection you already hold. Mirror once, then poll `lastChangeTimeSince` for what has changed (see [Request and response formats](request-and-response-formats.md)). Fewer, smaller requests stay comfortably inside the limits.
- **Match your polling to how often the data really changes.** Most collections change on the order of minutes, not milliseconds.

## What is not limited

Liveness probes (`diagnostic/health`, `diagnostic/version`) are never rate-limited, so a monitor can poll them freely. The platform's own first-party callers are also exempt; the limits exist to keep any one integration from crowding out the others, not to meter internal traffic.
