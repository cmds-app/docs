# CMDS Docs

Developer documentation for CMDS, published at [docs.cmds.app](https://docs.cmds.app) via GitHub Pages.

Built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/).

## Repository layout

| Folder   | Purpose |
| :------- | :------ |
| `dist`   | Build output (gitignored) |
| `docs`   | Markdown source for the documentation site |

`mkdocs.yml` is the site configuration. `requirements.txt` pins the Python dependencies.

## Prerequisites

- Python 3.10+
- PowerShell 7+ (for `tools\start.ps1`)

## Local development

Create the virtualenv and install dependencies (one-time):

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Serve with live reload:

```powershell
.\tools\start.ps1
```

Open <http://127.0.0.1:8000>.

## Build

```powershell
.\.venv\Scripts\python.exe -m mkdocs build
```

Output goes to `dist/docs/` (per `site_dir` in `mkdocs.yml`).

## Deployment

Pushes to `main` trigger a GitHub Pages build. The `docs.cmds.app` custom domain is configured in repo **Settings → Pages**.

## Contributing

Contribution guidelines live in [cmds-app/.github](https://github.com/cmds-app/.github) and apply to every CMDS project.

## License

[MIT](LICENSE)
