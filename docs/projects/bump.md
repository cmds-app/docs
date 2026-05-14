# Bump

A small HTTP API for managing semantic version numbers of named packages. Create a package, ask for its current version, and bump its major, minor, or patch component. State lives in PostgreSQL.

- **Repository:** [cmds-app/bump](https://github.com/cmds-app/bump)
- **License:** MIT
- **Stack:** ASP.NET Core minimal APIs on .NET 9, Dapper, Npgsql, Newtonsoft.Json

## Features

- CRUD for packages keyed by slug.
- Atomic `major` / `minor` / `patch` increment endpoints.
- Auto-creates a package on first increment if it does not exist.
- OpenAPI 3 document and Swagger UI.
- PascalCase JSON responses via Newtonsoft.Json.
- API-key authentication via `Authorization: Bearer <key>`.
- Liveness endpoint that probes the database.
- Path-base aware for hosting under a reverse proxy prefix.

## API reference

Base path: `/api/packages`.

| Method | Route                                  | Description                                           |
| :----- | :------------------------------------- | :---------------------------------------------------- |
| POST   | `/api/packages`                        | Create a new package (starts at `0.0.1`).             |
| GET    | `/api/packages`                        | List all packages.                                    |
| GET    | `/api/packages/{slug}`                 | Get one package.                                      |
| DELETE | `/api/packages/{slug}`                 | Delete a package.                                     |
| GET    | `/api/packages/{slug}/version`         | Get the current version string.                       |
| POST   | `/api/packages/{slug}/increment/major` | Bump major; create if missing (starts at `1.0.0`).    |
| POST   | `/api/packages/{slug}/increment/minor` | Bump minor; create if missing (starts at `0.1.0`).    |
| POST   | `/api/packages/{slug}/increment/patch` | Bump patch; create if missing (starts at `0.0.1`).    |
| GET    | `/api/health`                          | Liveness probe (200 healthy / 503 unhealthy).         |

All `/api/packages/*` endpoints require `Authorization: Bearer <key>`. `/api/health` and `/swagger` are open.

!!! tip "Interactive documentation"
    Every Bump deployment exposes a Swagger UI at `/swagger`. Click **Authorize** and paste a key (without the `Bearer ` prefix) to exercise the protected endpoints.

## Quick example

```bash
curl -X POST https://host/api/packages \
  -H 'Authorization: Bearer YOUR_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"Slug":"widget","Name":"Widget"}'

curl -X POST https://host/api/packages/widget/increment/patch \
  -H 'Authorization: Bearer YOUR_KEY'

curl https://host/api/packages/widget/version \
  -H 'Authorization: Bearer YOUR_KEY'
# -> {"Version":"0.0.2"}
```

See the [repository README](https://github.com/cmds-app/bump#readme) for installation, configuration, and release-build instructions.
