# Environment setup

How to set up the local environments you'll need to work on CMDS. Each section below covers one environment — pick the ones relevant to what you're building, and skip the rest.

If you find something missing or out of date, please update this page.

## Docs site

The developer documentation site for CMDS projects, published at **https://docs.cmds.app** via GitHub Pages. Built with [MkDocs](https://www.mkdocs.org/) and the [Material theme](https://squidfunk.github.io/mkdocs-material/).

### Local work environment

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mkdocs serve --livereload
```

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
mkdocs serve --livereload
```

Open <http://127.0.0.1:8000> — the site live-reloads on save.

### Build

```bash
mkdocs build --strict
```

Output is written to `dist/docs` (git-ignored).

### Deploying

Commits to `main` trigger `.github/workflows/docs.yml`, which builds the site and publishes to GitHub Pages. Enable **Settings → Pages → Source: GitHub Actions** on the repository, and point a `CNAME` DNS record from `docs.cmds.app` to the Pages host.

### Structure

```
docs/
├── changelog/      # Release notes and status updates
├── contributors/   # Docs for people who write CMDS code
│   ├── conventions/
│   ├── projects/
│   └── tools/
├── developers/     # Docs for integrators using the CMDS API
│   ├── api/
│   ├── getting-started/
│   ├── integrations/
│   └── resources/
├── guides/         # Task-based guides for end users
│   ├── orientation/
│   ├── registration/
│   └── user/
├── help/           # Terminology, tips, quick links
├── inline/         # Inline content snippets
├── projects/       # Per-project documentation
└── scorm/          # SCORM spec reference
```

Add new projects under `docs/projects/<name>.md` and register them in `mkdocs.yml`'s `nav`.

## .NET projects

> **Placeholder — to be written.**
>
> This section will cover setting up a local environment for CMDS's .NET code under `src/api/`, `src/lib/`, and `src/cli/`: required SDKs (.NET Framework 4.8, .NET Standard 2.0, .NET 9), IDE choice (Visual Studio 2022 or Rider), restoring and building the solution, running tests, and debugging against local services.

## Web (React)

> **Placeholder — to be written.**
>
> This section will cover the frontend environment for the lobby app under `src/web/`: Node.js version, package manager, installing dependencies, running the dev server, and connecting it to a local API.

## SQL Server database

> **Placeholder — to be written.**
>
> This section will cover installing a local SQL Server instance for CMDS development: edition and version, applying schema and migrations from `db/`, loading seed data, and the connection string conventions used across projects.

## SSRS reports

> **Placeholder — to be written.**
>
> This section will cover authoring the `.rptproj` reports that ship with CMDS: Visual Studio 2022 with the Microsoft Reporting Services Projects extension, deploying to a local SSRS instance, and previewing reports against development data.
