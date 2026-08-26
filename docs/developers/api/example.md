# Worked example: the compliance summary

If you integrate one endpoint against CMDS, it is almost certainly this one. The compliance summary answers a single question at scale: how does every member you select stand against every requirement that applies to them? It is the report our integrators pull into their own systems, so it makes a good first request to get working end to end.

This page walks through calling it: what you need first, how to shape the request, how to read the answer, and how to get the same data as a CSV.

## What the endpoint does

```
POST /reporting/compliance-summary
```

It scores each selected member against each measurement, per department. The result is a flat list: one row per member, per department, per measurement category. A row carries who the member is, which department the row is for, and their standing on that measurement - a score from 0 to 1, plus the counts behind it.

Because the result is members times departments times measurement categories, an unbounded request against a large organization returns tens of megabytes. So the endpoint requires you to narrow the request on at least one axis, and answers `400` if you do not. That rule is covered under [Bounding your request](#bounding-your-request).

## Before you start

You need three things in place:

1. **A personal API secret.** This is the credential you send with the request. Generate one on your account page once API access is enabled - see [Authentication](authentication.md).
2. **Report access.** The compliance report reads a whole organization's standing, so it is gated more tightly than the rest of the API. An operator has to grant your account report access on the Security > Accounts page, on top of API access. Without it the endpoint answers `403`, even with a working secret.
3. **Your base address.** Use the environment you are integrating against - `https://api.cmds.app` for production, or `https://test-api.cmds.app` for the sandbox. See [Introduction](introduction.md).

Your personal secret carries its own organization, so you do not send an `X-Tenant` header with it.

## Step 1: Shape the request

The request body names what to report on. Every field is optional, but the request as a whole has to be bounded. The simplest valid request names one department, which reports every member in it against every measurement:

```json
{
    "departments": ["3f2504e0-4f89-41d3-9a0c-0305e82c3301"]
}
```

To narrow further, name specific members and specific measurements instead:

```json
{
    "members": ["7c9e6679-7425-40de-944b-e07fc1f90ae7"],
    "measurements": [3, 4]
}
```

The identifiers are the department, member, and measurement ids you already hold from the directory reads. Leave a list out (or send it as `null`) to mean "all of them" for that axis.

## Step 2: Send it

The format is chosen with a `?format=` query parameter. Omit it for JSON, the default.

### curl (Linux / macOS)

```bash
curl -X POST "https://api.cmds.app/reporting/compliance-summary" \
    -H "Authorization: Bearer vsk_live_your_secret_here" \
    -H "Content-Type: application/json" \
    -d '{
        "departments": ["3f2504e0-4f89-41d3-9a0c-0305e82c3301"]
    }'
```

### PowerShell (Windows)

```powershell
$secret = "vsk_live_your_secret_here"

$body = @'
{
    "departments": ["3f2504e0-4f89-41d3-9a0c-0305e82c3301"]
}
'@

curl.exe -X POST "https://api.cmds.app/reporting/compliance-summary" `
    -H "Authorization: Bearer $secret" `
    -H "Content-Type: application/json" `
    -d $body
```

## Step 3: Read the response

A successful request returns `200` and a JSON array. Each element is one member's standing on one measurement, within one department:

```json
[
    {
        "department": { "id": "3f2504e0-4f89-41d3-9a0c-0305e82c3301", "name": "Operations", "code": null },
        "member": { "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7", "name": "Jordan Avery", "code": "100482" },
        "primaryProfile": { "id": "b1e7…", "name": "Field Operator", "code": "FO-2" },
        "measurement": {
            "key": 3,
            "name": "Required credentials",
            "score": 0.75,
            "required": 4,
            "satisfied": 3,
            "expired": 1,
            "notCompleted": 0,
            "notApplicable": null,
            "needsTraining": null,
            "selfAssessed": null,
            "submitted": null,
            "validated": null
        }
    }
]
```

A few things worth knowing when you read this:

- **`measurement.score`** runs from 0 to 1, to two decimal places - the share of what was required that the member has satisfied. It is `null` when a score does not apply to the row.
- **`measurement.key`** is opaque. The underlying view numbers the same category differently on its credential and competency branches, so pair the key with `measurement.name` rather than treating the key as a stable identifier.
- **`measurement.required` and `measurement.satisfied`** are the counts behind the score. The remaining counts (`expired`, `notCompleted`, and the rest) break the standing down further and are `null` where they do not apply.
- **`primaryProfile`** is `null` when the member has no primary profile.

## Step 4: Get it as a CSV

Add `?format=csv` to receive the same data as a `text/csv` file attachment, one row per member per measurement - the same shape as the JSON, flattened:

```bash
curl -X POST "https://api.cmds.app/reporting/compliance-summary?format=csv" \
    -H "Authorization: Bearer vsk_live_your_secret_here" \
    -H "Content-Type: application/json" \
    -d '{ "departments": ["3f2504e0-4f89-41d3-9a0c-0305e82c3301"] }' \
    -o compliance-summary.csv
```

The CSV leads with a UTF-8 byte order mark so a spreadsheet reads accented names correctly, and it guards against formula injection in caller-supplied fields. `xlsx` and `pdf` are named formats but answer `501` until their renderers exist; anything else answers `400`.

## Bounding your request

The endpoint returns `400` rather than running an unbounded report. Two rules apply:

- If you include **every** measurement type (an empty or omitted `measurements`), you must name at least one department.
- Otherwise, you must name at least one department or at least one member.

In practice: name a department, or name members together with the measurements you want. An explicit `null` for a list means "no filter" and is not an error.

## Request fields

| Field | Type | Meaning |
| :--- | :--- | :--- |
| `departments` | array of ids | Departments to report on. Empty or omitted means all |
| `members` | array of ids | Members to report on. Empty means everybody in the selected departments |
| `measurements` | array of integers | Measurement keys to include. Empty means all categories |
| `functions` | array of strings | Affiliation functions to count: `Department`, `Organization`, `Administration`. Empty means all |
| `profileCondition` | integer | Which profiles the score counts against: `0` all (default), `1` primary only, `2` compliance-required only |
| `memberMustHaveProfile` | boolean | When true, drop members who have no profile at all |
| `emptyScore` | integer | How to score a member with nothing to satisfy: `0` as reported (default), `1` non-compliant, `2` compliant, `3` excluded |

## Responses

| Status | Meaning |
| :--- | :--- |
| `200 OK` | The report, as a JSON array (or a CSV attachment with `?format=csv`) |
| `400 Bad Request` | The request is unbounded (see above), or names an unknown format |
| `401 Unauthorized` | No valid credential |
| `403 Forbidden` | Your account has not been granted report access |
| `501 Not Implemented` | A named but unbuilt format (`xlsx`, `pdf`) |

## A note on freshness

The report reads a materialized snapshot of member standing. It reports what the snapshot says and never triggers a rebuild, so the numbers are exactly as fresh as the last refresh - fast to return, but not a live recomputation at the moment you call.
