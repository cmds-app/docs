# Example: compliance summary reporting

The compliance summary answers one of the most important questions for companies using CMDS:

* What is the current status for every employee and contractor with regard to the occupational requirements that apply to them?

This API endpoint returns the data to answer that question, so it is the data that integrators often pull into their own systems.

This page walks through the steps to call it: what you need first, how to structure your API request, how to read the response, and how to get the same data in a CSV file format.

> A quick note on the lexicon: This document uses the term "CMDS Member" (or simply abbreviated "member") to mean any person who is assigned competencies and/or training within the CMDS platform. This term is intended to include workers, employees, contractors, trainees, learners, students, candidates, etc.

## What the endpoint does

```
POST /reporting/compliance-summaries
```

It scores each selected member against each measurement, per department. The result is a flat list: one row per member, per department, per measurement category. A row carries who the member is, which department the row is for, and their status on that measurement - a score from 0 to 1, plus the counts used to calculate the score.

Because the result is `members X departments X measurement categories`, an unbounded request against a large company might return tens of megabytes. Therefore, this endpoint requires you to narrow your request on at least one axis; it responds with an `HTTP 400` error if you do not. This rule is covered under [Bounding your request](#bounding-your-request).

## Before you start

You need three things in place:

1. **An API secret.** This is the credential you send with the request: either the API client secret shown on your profile page in CMDS V4, or a personal secret you generate on your account page in this platform. Both need the Developer role - see [Authentication](authentication.md).
2. **Report access.** The compliance report reads your entire organization's status, so access to it is more restricted than other parts of the API. An operator must grant report access to your account on the Security > Accounts page (in addition to the Developer role). Without it the endpoint answers `403`, even with a working secret.
3. **Your base address.** Use the environment you are integrating against - `https://test-api.cmds.app` (Test) while you build, and `https://live-api.cmds.app` (Live) when your integration is ready. See [Introduction](introduction.md).

Your secret belongs to your account in one organization, so you do not send a request header that identifies your company (`X-Company`). A request that names a different company in that header is refused with `403`.

## Step 1: Structure the request

The request body defines your report criteria. Every field is optional, but the request as a whole must be bounded - see [Bounding your request](#bounding-your-request). The simplest valid criteria specifies one department; this returns every compliance measurement for every member in the requested department:

```json
{
    "departments": ["3f2504e0-4f89-41d3-9a0c-0305e82c3301"]
}
```

Alternatively, you can specify individual members and/or specific measurements:

```json
{
    "members": ["7c9e6679-7425-40de-944b-e07fc1f90ae7"],
    "measurements": [3, 4]
}
```

You can obtain all the department and member identifiers in your company using the `GET /reporting/directory-contacts` endpoint. It needs report access, the same as this endpoint.

You can obtain all the measurement keys and names using the `GET /reporting/compliance-summaries/measurements` endpoint. It needs no report access.

You can omit a list (or send `null`) to mean "all of the items in the list" for that axis.

## Step 2: Send it

The format is chosen with a `?format=` query parameter. If you omit the format, the default is JSON.

Supported formats are `csv` and `json`.

### curl

```bash
curl -X POST "https://test-api.cmds.app/reporting/compliance-summaries" \
    -H "Authorization: Bearer your_client_secret_here" \
    -H "Content-Type: application/json" \
    -d '{
        "departments": ["3f2504e0-4f89-41d3-9a0c-0305e82c3301"]
    }'
```

### PowerShell

```powershell
$secret = "your_client_secret_here"

$body = @{
    departments = @("3f2504e0-4f89-41d3-9a0c-0305e82c3301")
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "https://test-api.cmds.app/reporting/compliance-summaries" `
    -Headers @{ Authorization = "Bearer $secret" } `
    -ContentType "application/json" `
    -Body $body
```

## Step 3: Read the response

A successful request returns `200` and a JSON array. Each element is one member's standing on one measurement, within one department:

```json
[
    {
        "department": { "id": "3f2504e0-4f89-41d3-9a0c-0305e82c3301", "name": "Operations", "code": null },
        "member": { "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7", "name": "Jordan Avery", "code": "100482" },
        "primaryProfile": { "id": "b1e7...", "name": "Field Operator", "code": "FO-2" },
        "measurement": {
            "key": 3,
            "name": "Critical Competencies",
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

- **`measurement.score`** runs from 0 to 1, to two decimal places - the share of what was required that the member has satisfied. A member with nothing required (`required` is `0`) is scored by the `emptyScore` field: by default they score `1`, and with `emptyScore` set to `3` (excluded) the score is `null`.
- **`measurement.key`** runs from 1 to 12, one key per measurement, and is what the `measurements` filter takes. `GET /reporting/compliance-summaries/measurements` lists every key with its name.
- **`measurement.required` and `measurement.satisfied`** are the counts behind the score. The remaining counts (`expired`, `notCompleted`, and the rest) break the standing down further and are `null` where they do not apply.
- **`primaryProfile`** is `null` when the member has no primary profile.

## Step 4: Get it as a CSV

Add `?format=csv` to receive the same data as a `text/csv` file attachment, one row per member per department per measurement - the same data as the JSON, flattened into its own column names:

```bash
curl -X POST "https://live-api.cmds.app/reporting/compliance-summaries?format=csv" \
    -H "Authorization: Bearer your_client_secret_here" \
    -H "Content-Type: application/json" \
    -d '{ "departments": ["3f2504e0-4f89-41d3-9a0c-0305e82c3301"] }' \
    -o compliance-summary.csv
```

The CSV leads with a UTF-8 byte order mark so a spreadsheet reads accented names correctly, and it guards against formula injection in caller-supplied fields.

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
| `functions` | array of strings | Affiliation functions to count: `Department`, `Organization`, `Administration`, `Employee`. Empty means the first three; an `Employee` affiliation counts only when you name it |
| `profileCondition` | integer | Which profiles the score counts against: `0` all (default), `1` primary only, `2` compliance-required only |
| `memberMustHaveProfile` | boolean | When true, drop members who have no profile at all |
| `emptyScore` | integer | How to score a member with nothing to satisfy: `0` as reported (default), `1` non-compliant, `2` compliant, `3` excluded |

## Responses

| Status | Meaning |
| :--- | :--- |
| `200 OK` | The report, as a JSON array (or a CSV attachment with `?format=csv`) |
| `400 Bad Request` | The request is unbounded (see above), or names an unknown format |
| `401 Unauthorized` | No valid credential |
| `403 Forbidden` | Your account has not been granted report access, or the `X-Company` header names a company other than your secret's |
| `429 Too Many Requests` | You have exceeded the report rate limit; wait for the number of seconds in `Retry-After` |
| `501 Not Implemented` | A named but unbuilt format (`xlsx`, `pdf`) |

## How fresh is the data?

The report is calculated when you call it, from copies of live CMDS data rather than from a direct connection to the live operational platform. How current those copies are depends on what changed:

- **Records.** Validations, tickets, designations, memberships, and accounts are copied every hour, so a change made in CMDS is visible to the API within the hour.
- **Definitions.** Departments, profiles, competencies, and achievement types are copied once a day, so these changes are available through the API the next day.
- **Expiry.** Expiry is calculated when you send your request to the API, so a validation or ticket that expired this morning counts as expired immediately, without waiting for a copy.

Two API requests, one hour apart from each other, can return different results even when nobody has changed any data, following an expiry date or the hourly copy.
