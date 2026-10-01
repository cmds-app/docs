# Folder structure

Every folder at the root of the repository has one job, and the name tells you which lifecycle its contents belong to. A script that a developer runs against a local clone, a script that runs on a production server, and a file that only exists while you work are three different things, so they live in three different places.

| Folder    | Purpose |
| :-------- | :------ |
| `.config` | Local .NET tool manifest (`dotnet-tools.json`), so `dotnet tool restore` installs the tools the repository uses. |
| `.github` | CI workflows. Each workflow is path-filtered to one surface, so a change to the web app does not rebuild the API. |
| `build`   | Release build scripts. They obtain the version number, compile, package, and hand the packages to deployment. |
| `config`  | Application settings (`appsettings.json`). Secrets live in `appsettings.work.json`, which is gitignored; the committed file holds empty placeholders. |
| `db`      | Everything the database is built from: `migrations/`, `schema.sql`, `export-schema.ps1`, seed scripts, and `fixtures/`. |
| `design`  | The design system: tokens, styles, and guidelines for the web app. |
| `docfx`   | The code reference site, generated from the XML documentation comments in `src/`. |
| `docs`    | Technical documentation for the repository: plans, decisions, and deployment notes. |
| `ops`     | Server operations scripts, deployed with the app and run by operators or a scheduler against a live environment. |
| `src`     | .NET source code, one folder per project. |
| `tests`   | xUnit test projects, one for each source project that has tests, named `<Project>.Tests`, and `tests/manual/` for by-hand verification scripts. |
| `tmp`     | Transient runtime state: `tmp/logs/<subsystem>/`, `tmp/pids/`, `tmp/data/`. Gitignored. |
| `training` | Training material built from the repository, such as the notification course. |
| `tools`   | Dev-loop scripts you run against your own clone, such as `start.ps1`, `stop.ps1`, and `restore-database.ps1`. |
| `web`     | The web app (Vite, React, and TypeScript). It is its own package, built and deployed separately from the API. |

A folder is added only when there is something to put in it, so a smaller repository may have fewer of these.

## Notes

**`tools` versus `ops`**

Both hold PowerShell scripts, but they run in different places. A script in `tools/` runs on a developer's machine against a local clone and a local database. A script in `ops/` is packaged with a release and runs on a server against a real environment. Keeping the two apart means a dev-loop convenience never ships to production by accident.

**`web` sits at the root**

The web app is a sibling of `src/`, never nested inside a .NET project. It has its own toolchain (ESLint, Prettier, Vitest, and a `typecheck` script), its own CI workflow, and its own release package, so a web release does not redeploy the API.

**`db/fixtures` holds data files**

Data files and templates read by import or generate commands go in `db/fixtures/`, not loose in `db/`. The root of `db/` holds only migrations, schema artifacts, seed scripts, and `export-schema.ps1`.

**Build output is not committed**

`dist/` holds build output and is gitignored, along with `tmp/`. A release comes from a build, never from files checked into the repository.
