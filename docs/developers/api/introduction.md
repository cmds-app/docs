# Introduction

The CMDS API is a RESTful interface built on [HTTPS](https://datatracker.ietf.org/doc/html/rfc2818) requests and [JSON](https://www.json.org/json-en.html) responses, so you can work with it from the programming language of your choice. It reads the data in your account - accounts, members, teams, achievements, certification records, and more - and carries out a set of actions on it, through one secure, organization-scoped surface.

!!! info
    API access is granted per account. An operator enables it for your account before you can generate a credential. If you need access, contact CMDS Administration (<admin_cmds@keyera.com>) or ask your operator to enable it on the Security > Accounts page.

## Base address

The API has its own host per environment. Append a route directly to it - there is no `/api` or version segment in the path.

| Environment | API base address | For |
| :--- | :--- | :--- |
| Live | `https://api.cmds.app` | Production - real data |
| Test | `https://test-api.cmds.app` | Building and validating an integration before it goes Live |

Every request must be secured over HTTPS on port 443.

Throughout these pages, an endpoint is written as its route relative to that base - `me/client-secret` means `https://api.cmds.app/me/client-secret` on Live. Where an example needs a full URL, it uses Live.

## Naming your organization

CMDS serves many organizations, so most requests have to say which organization they act for. API URLs carry no organization segment. Instead, you name the organization in the `X-Company` request header - or you let your credential carry it, which a personal API secret does. The details, and the one case where you can omit it, are on the [Authentication](authentication.md) page.

## Authentication

The API authenticates each request with a **personal API secret**, a credential you generate on your own account once an operator has enabled API access. It also accepts a shared service key for server-to-server callers and a session cookie for browser-based integrations.

See [Authentication](authentication.md) for how to generate a secret, how to send it, and how the other two methods fit.

## Requests and responses

Responses are JSON with camelCase property names. Directory collections come back as plain JSON arrays with no paging: the endpoint returns the whole collection, and you bound the next read by its last change time. Search collections, such as certification plans and competencies, come back one page at a time in a small envelope. Errors follow [RFC 9457](https://datatracker.ietf.org/doc/html/rfc9457) problem+json, with a few plain JSON exceptions.

The full rules - HTTP methods, field selection, paging, incremental reads, status codes, and error shape - are on the [Request and response formats](request-and-response-formats.md) page.

## OpenAPI specification

The API describes itself with an [OpenAPI](https://github.com/OAI/OpenAPI-Specification) document. The Test environment serves an interactive Swagger UI at `https://test-api.cmds.app/swagger`; Live does not. To try a request there, paste a personal API secret generated on Test into the **Authorize** box (the `Bearer` scheme) and the authenticated surface opens up.

We use [Insomnia](https://insomnia.rest) and [Postman](https://www.postman.com) to design and test the API, and either is a good tool for exploring your own requests against it.

## Need help?

Send any questions to CMDS Administration (<admin_cmds@keyera.com>).
