# Reporting endpoints

These endpoints answer the questions most integrations exist to answer: who is missing a requirement, who is in which department, how each person stands against their requirements, and how that has changed over time. This page shows how to call each one and what comes back.

| Endpoint | Method | Answers | Needs report access |
| :--- | :--- | :--- | :--- |
| [`/reporting/achievement-gaps`](#achievement-gaps) | `GET` | Who does not hold a valid ticket for one achievement | No |
| [`/reporting/directory-contacts`](#directory-contacts) | `GET` | Your departments, the people in them, and who is in which | Yes |
| [`/reporting/compliance-summaries`](#compliance-summaries) | `POST` | How each person stands against each requirement, today | Yes |
| [`/reporting/compliance-trends`](#compliance-trends) | `POST` | How each department's compliance has changed, month by month | Yes |
| [`/reporting/monthly-statistics`](#monthly-statistics) | `GET` | Each person's standing on mandatory critical competencies at the end of a month | Yes |

## Before you start

Every request needs the same three things:

- **Your API secret**, sent in the `Authorization` header as the word `Bearer`, a space, and the secret: `Authorization: Bearer your_client_secret_here`. Either the API client secret from Developer Settings on your CMDS profile page or a personal secret works on every endpoint here. Both need the Developer role. See [Authentication](authentication.md).
- **Report access**, for the four endpoints marked above. An operator grants it on the Security > Accounts page. Without it those endpoints answer `403`.
- **The base address** of the environment you are calling: `https://test-api.cmds.app` while you build, `https://api.cmds.app` when your integration is ready.

Your secret belongs to your account in one organization, and every endpoint here reports on that organization alone. You do not send an `X-Company` header.

The examples use PowerShell. Every request works the same way from any tool that can send an HTTP request with a header.

## Achievement gaps

Lists the people who should hold an achievement and do not hold a valid ticket for it: some have no ticket at all, and the rest hold one that is Expired, Pending, or Submitted.

### Request

```
GET /reporting/achievement-gaps?achievementId={id}
```

| Parameter | Required | Meaning |
| :--- | :--- | :--- |
| `achievementId` | Yes | The achievement to report on. List the choices with `/reporting/achievement-gaps/achievements` (below) |
| `personTypes` | No | Which kinds of people count, such as `Employee`. Repeat it for more than one. Omit it for every kind your organization uses |
| `status` | No | Only one kind of gap: `missing` (no ticket at all), `Expired`, `Pending`, or `Submitted` |
| `q` | No | Find people by name. Every word must appear in the name, in any order |
| `sort` | No | `name` (the default), `status` (people with no ticket first), or `expires` (soonest expiry first) |
| `direction` | No | `asc` (the default) or `desc` |
| `page`, `pageSize` | No | Which page of people to return. The page size is 25 by default and at most 200 |
| `format` | No | `json` (the default) or `csv`. A CSV holds every row, not one page |

Two short lists help you build the request:

- `GET /reporting/achievement-gaps/achievements` lists the achievements you can report on, most widely held first. It takes `q` to search by name, and `page` and `pageSize`.
- `GET /reporting/achievement-gaps/person-types` lists the person types your organization uses, such as `["Contingent Worker", "Employee"]`.

```powershell
$secret = "your_client_secret_here"
$headers = @{ Authorization = "Bearer $secret" }

Invoke-RestMethod -Headers $headers `
    -Uri "https://test-api.cmds.app/reporting/achievement-gaps?achievementId=4478cbc7-270e-4d7f-8428-a9b801043d3c&personTypes=Employee"
```

### Response

```json
{
    "achievement": {
        "achievementId": "4478cbc7-270e-4d7f-8428-a9b801043d3c",
        "achievementName": "General Orientation",
        "achievementType": "Orientation",
        "companyId": "657b5405-68d3-4a7a-95a3-c4e19d101352"
    },
    "summary": {
        "roster": 2680,
        "excludedNoPersonType": 69576,
        "valid": 1406,
        "gaps": 1274,
        "standings": [
            { "status": "missing", "hasTicket": false, "people": 545 },
            { "status": "Pending", "hasTicket": true, "people": 417 },
            { "status": "Expired", "hasTicket": true, "people": 312 }
        ]
    },
    "items": [
        {
            "learnerAccountId": "2f55bb95-4e22-4d4a-b842-af330151c264",
            "learnerName": "Jordan Avery",
            "email": "jordan.avery@example.com",
            "personCode": "000072167",
            "personType": "Employee",
            "jobTitle": "Field Operator",
            "hasTicket": true,
            "ticketId": "ba51c7c1-7446-418d-ab55-b387014cae87",
            "status": "Pending",
            "issuedAt": null,
            "expiresAt": null
        }
    ],
    "total": 1274,
    "page": 1,
    "pageSize": 25
}
```

- **`summary`** counts the whole roster, whatever page you asked for: `roster` people should hold the achievement, `valid` of them do, and `gaps` do not. `excludedNoPersonType` is the people left out because they have no person type.
- **`items`** is one page of the gaps. `hasTicket` is `false` for someone with no ticket at all, and then `status` is `null`.
- **`total`** is how many gaps match your `status` filter, so you know how many pages there are.

## Directory contacts

Lists your organization's departments, the people in them, and which people are in which departments. Use it to find the department and member ids that `compliance-summaries` takes.

### Request

```
GET /reporting/directory-contacts
```

It takes no parameters.

```powershell
$contacts = Invoke-RestMethod -Headers $headers -Uri "https://test-api.cmds.app/reporting/directory-contacts"

"{0} departments, {1} members, {2} affiliations" -f $contacts.departments.Count, $contacts.members.Count, $contacts.affiliations.Count
```

### Response

```json
{
    "departments": [
        { "id": "03d39c01-0db5-c57a-87fa-7edb84e3037b", "name": "Central Foothills Field" }
    ],
    "members": [
        { "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7", "name": "Jordan Avery", "email": "jordan.avery@example.com" }
    ],
    "affiliations": [
        {
            "memberId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
            "departmentId": "03d39c01-0db5-c57a-87fa-7edb84e3037b",
            "function": "Department"
        }
    ]
}
```

- **The people are exactly the ones the compliance summary reports on.** Someone in no department, or without access to CMDS, is not listed.
- **Every `memberId` and `departmentId`** in `affiliations` appears in the other two lists.
- **`function`** says how the person belongs to the department: `Department`, `Organization`, `Administration`, or `Employee`. The compliance summary counts the first three unless you ask otherwise.

## Compliance summaries

Shows how each person stands against each of the twelve compliance measurements, per department, as of the moment you call. The [worked example](example.md) walks through this endpoint in detail; what follows is the short version.

### Request

```
POST /reporting/compliance-summaries
```

The body says what to report on. The request has to be narrowed: name at least one department, or name people together with the measurements you want.

```json
{
    "departments": ["03d39c01-0db5-c57a-87fa-7edb84e3037b"],
    "measurements": [3, 4]
}
```

| Field | Meaning |
| :--- | :--- |
| `departments` | Department ids, from `/reporting/directory-contacts` |
| `members` | Member ids, from `/reporting/directory-contacts`. Omit them for everybody in the departments |
| `measurements` | Measurement keys, 1 to 12. Omit them for all twelve |

`GET /reporting/compliance-summaries/measurements` lists the twelve keys with their names, and needs no report access. Add `?format=csv` to the address to receive a CSV file instead of JSON. The worked example lists the remaining optional fields.

```powershell
$body = @{ departments = @("03d39c01-0db5-c57a-87fa-7edb84e3037b") } | ConvertTo-Json

Invoke-RestMethod -Method Post -Headers $headers -ContentType "application/json" -Body $body `
    -Uri "https://test-api.cmds.app/reporting/compliance-summaries"
```

### Response

One row per person, per department, per measurement:

```json
[
    {
        "department": { "id": "03d39c01-0db5-c57a-87fa-7edb84e3037b", "name": "Central Foothills Field", "code": null },
        "member": { "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7", "name": "Jordan Avery", "code": "100482" },
        "primaryProfile": null,
        "measurement": {
            "key": 3,
            "name": "Critical Competencies",
            "score": 0.75,
            "required": 4,
            "satisfied": 3,
            "expired": 1,
            "notCompleted": 0,
            "notApplicable": 0,
            "needsTraining": 0,
            "selfAssessed": 0,
            "submitted": 0,
            "validated": 3
        }
    }
]
```

`score` runs from 0 to 1 and is `satisfied` divided by `required`. A person with nothing required scores `1` unless you ask otherwise.

## Compliance trends

Shows each department's score on each measurement, month by month, over the last 12 or 24 months. It is the data behind the Compliance Trend report in CMDS.

### Request

```
POST /reporting/compliance-trends
```

Every field is optional; an empty body (`{}`) returns every department, every measurement, over 12 months.

```json
{
    "departments": ["03d39c01-0db5-c57a-87fa-7edb84e3037b"],
    "measurements": [3, 4],
    "months": 24,
    "profileCondition": "compliance"
}
```

| Field | Meaning |
| :--- | :--- |
| `departments` | Department ids, from `/reporting/directory-contacts`. Omit them for every department |
| `measurements` | Measurement keys, 1 to 12. Omit them for all twelve |
| `months` | `12` (the default) or `24`: calendar months ending with this one |
| `profileCondition` | `compliance` (the default) counts the profiles that require compliance; `primary` counts primary profiles only |

```powershell
$body = @{ departments = @("03d39c01-0db5-c57a-87fa-7edb84e3037b"); months = 24 } | ConvertTo-Json

Invoke-RestMethod -Method Post -Headers $headers -ContentType "application/json" -Body $body `
    -Uri "https://test-api.cmds.app/reporting/compliance-trends"
```

### Response

One row per department, per measurement, per month:

```json
[
    {
        "department": { "id": "03d39c01-0db5-c57a-87fa-7edb84e3037b", "name": "Central Foothills Field", "code": null },
        "measurement": { "key": 3, "name": "Critical Competencies" },
        "month": "2026-09",
        "snapshotDate": "2026-09-06",
        "required": 87,
        "satisfied": 73,
        "score": 0.8391
    }
]
```

- **`score`** is the department's `satisfied` divided by its `required`, to four decimal places: the department as a whole, not an average of its people's scores. It is `null` when nothing was required.
- **`month`** is read from the last snapshot CMDS took in that month, which is `snapshotDate`. A month with no snapshot has no rows.
- **The numbers match the Compliance Trend report in CMDS**, not the compliance summary: the trend reads the weekly history CMDS keeps, and the summary is calculated when you call it.

## Monthly statistics

Lists each person's standing on mandatory critical competencies, primary and secondary, in your organization's facility departments, as at the last snapshot taken in a month.

### Request

```
GET /reporting/monthly-statistics?year={year}&month={month}
```

| Parameter | Required | Meaning |
| :--- | :--- | :--- |
| `year` | Yes | The calendar year, such as `2026` |
| `month` | Yes | The calendar month, `1` to `12` |
| `legacy` | No | `true` returns the same rows in the shape the CMDS V4 API used: the V4 names (`UserName`, `JoinIdentifier`, `CountRQ`), and a count of zero or an empty value is left out rather than written. `false` is the default |

```powershell
Invoke-RestMethod -Headers $headers -Uri "https://test-api.cmds.app/reporting/monthly-statistics?year=2026&month=8"
```

If your integration was written against the CMDS V4 `api/cmds/reports/statistics` endpoint, add `&legacy=true` and it can read the rows without changes.

### Response

One row per person, per department, per competency category:

```json
[
    {
        "id": "4b1fd754-a58c-40bf-aed5-37f1c7b84a2a",
        "companyId": "657b5405-68d3-4a7a-95a3-c4e19d101352",
        "companyName": "KEYERA",
        "departmentId": "8c5f604c-5dbe-4938-9c09-9d8ec78f141f",
        "departmentName": "AEF - General",
        "departmentRole": "Department",
        "memberId": "ebb09983-bc09-4375-8e87-f2baa50656f5",
        "memberName": "Jordan Avery",
        "itemNumber": 5,
        "itemName": "Mandatory Critical Secondary Competency",
        "listDomain": "Standard",
        "listFolder": "Competency",
        "tagCriticality": "Critical",
        "tagNecessity": "Mandatory",
        "tagPrimacy": "Secondary",
        "required": 6,
        "validated": 6,
        "expired": 0,
        "notCompleted": 0,
        "notApplicable": 0,
        "notApplicableValidated": 0,
        "needsTraining": 0,
        "selfAssessed": 0,
        "submitted": 0,
        "completed": 0,
        "progress": 1.0,
        "score": 1.0,
        "asAt": "2026-08-01T00:00:00-06:00"
    }
]
```

The counts are competencies in each state. With `legacy=true` each count has the CMDS V4 name in the second column, and a count of zero is left out:

| Field | V4 name | Counts competencies that are |
| :--- | :--- | :--- |
| `required` | `CountRQ` | Required |
| `validated` | `CountVA` | Validated |
| `expired` | `CountEX` | Expired |
| `notCompleted` | `CountNC` | Not completed |
| `notApplicable` | `CountNA` | Not applicable |
| `notApplicableValidated` | `CountVN` | Not applicable and validated |
| `needsTraining` | `CountNT` | Needs training |
| `selfAssessed` | `CountSA` | Self-assessed |
| `submitted` | `CountSV` | Submitted for validation |
| `completed` | `CountCP` | Completed |

`memberId` is the same id `/reporting/directory-contacts` and `/reporting/compliance-summaries` use for a member, so you can match rows across the three.

A month in which no snapshot was taken returns an empty list (`[]`), not an error. `asAt` is when the snapshot was taken.

## When something goes wrong

An error comes back as a JSON object with a `title` saying what went wrong, a `detail` saying what to do about it, and, for a problem with your secret, a `code` an integration can check:

| Status | Meaning |
| :--- | :--- |
| `400 Bad Request` | The request is missing something or asks for something the endpoint cannot do; the `detail` names it |
| `401 Unauthorized` | Your secret was not sent, not recognized, or has expired; the `detail` says which |
| `403 Forbidden` | Your secret is genuine, but its account does not have the Developer role or report access |
| `404 Not Found` | The achievement you named does not exist in your organization |
| `429 Too Many Requests` | Too many requests in a short time; wait the number of seconds in the `Retry-After` header. See [Rate limits and throttling](rate-limits-and-throttling.md) |
