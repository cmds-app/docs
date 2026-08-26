# Introduction

The CMDS API is a RESTful interface built on [HTTPS](https://datatracker.ietf.org/doc/html/rfc2818) requests and [JSON](https://www.json.org/json-en.html) responses, so you can work with it from the programming language of your choice. It reads the data in your account - accounts, members, teams, achievements, certification records, and more - through one secure, tenant-scoped surface.

!!! info
    API access is granted per account. An operator enables it for your account before you can generate a credential. If you need access, [contact our service and support team](mailto:support@cmds.app) or ask your operator to enable it on the Security > Accounts page.

## Base address

The API has its own host per environment. Append a route directly to it - there is no `/api` or version segment in the path.

| Environment | API base address | For |
| :--- | :--- | :--- |
| Live | `https://api.cmds.app` | Production - real data |
| Test | `https://test-api.cmds.app` | A sandbox for building and validating an integration |

Every request must be secured over HTTPS on port 443.

Throughout these pages, an endpoint is written as its route relative to that base - `me/client-secret` means `https://api.cmds.app/me/client-secret` on Live. Where an example needs a full URL, it uses Live.

## Naming your organization

CMDS is multitenant, so most requests have to say which organization they act for. API URLs carry no tenant segment. Instead, you name the organization in the `X-Tenant` request header - or you let your credential carry it, which a personal API secret does. The details, and the one case where you can omit it, are on the [Authentication](authentication.md) page.

## Authentication

The API authenticates each request with a **personal API secret**, a credential you generate on your own account once an operator has enabled API access. It also accepts a shared service key for server-to-server callers and a session cookie for browser-based integrations.

See [Authentication](authentication.md) for how to generate a secret, how to send it, and how the other two methods fit.

## Requests and responses

Responses are JSON with camelCase property names. Collections come back as plain JSON arrays - no envelope, no file attachment - and there is no page/offset paging: a collection endpoint returns the whole collection, and you bound the next read by its last change time. Errors follow [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) problem+json.

The full rules - HTTP methods, field selection, incremental reads, status codes, and error shape - are on the [Request and response formats](request-and-response-formats.md) page.

## OpenAPI specification

The API describes itself with an [OpenAPI](https://github.com/OAI/OpenAPI-Specification) document. Development builds serve an interactive Swagger UI at `/swagger`; to try a request there, paste a personal API secret into the **Authorize** box (the `Bearer` scheme) and the authenticated surface opens up.

We use [Insomnia](https://insomnia.rest) and [Postman](https://www.postman.com) to design and test the API, and either is a good tool for exploring your own requests against it.

## Need help?

Send email to the CMDS service and support team with any questions: [support@cmds.app](mailto:support@cmds.app).
