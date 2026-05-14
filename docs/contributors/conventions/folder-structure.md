# Folder structure

A git repository should contain some (or all) of the following root-level folders. Not every project needs every folder — add one only when there is content to put in it.

| Folder    | Heading                         | Purpose |
| :-------- | :------------------------------ | :------ |
| `build`   | Build configuration and tooling | Developer-written scripts, configuration files, environment setup files, and utilities to automate and orchestrate build-related tasks such as linting, compiling, bundling, transforming, and deploying source code. |
| `config`  | Project configuration files     | Configuration files, environment settings, dependency injection configuration, etc. |
| `data`    | Project data assets             | Reference datasets, example data, fixtures, and non-database data files used by or bundled with the project. |
| `db`      | Database schema and migrations  | SQL schema definitions (DDL), migration scripts, seed data, and other files that describe or populate the project's database. |
| `dist`    | Build output artifacts          | Compiled, bundled, and/or generated files produced by the build process. This folder represents the deployable or distributable form of the project. (It should be excluded from version control.) |
| `docs`    | Project documentation           | Technical documentation related to the project. Includes markdown files, HTML files, API references, user guides, architecture overviews, or other documents that provide instructions, tutorials, and reference materials for developers. |
| `public`  | Static web-visible resources    | Static files used in the project and intended to be publicly accessible. These might include images, icons, fonts, HTML/CSS/JS files, and other media assets. |
| `src`     | Application source code         | Source code files. Projects may be organized into subfolders by type: api, cli, lib, web  |

**Notes:**

**`db` vs `data`**

Use `db/` for anything the database reads or is built from — schema DDL, migrations, seed SQL. Use `data/` for non-database assets such as reference CSV/JSON files, test fixtures, or example datasets. Most database-backed projects will have `db/` and may never need `data/`.

**`dist` is not committed**

`dist/` holds build outputs and must be listed in `.gitignore`. The release build process populates it; consumers pull its contents from a release artifact rather than from version control.
