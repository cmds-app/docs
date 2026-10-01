# Project names

The name of a .NET project uses Pascal case: the first letter of each word is capitalized, with no spaces or separators between words. A dot separates the product from the part of the product the project builds.

Projects sit directly under `src/`, one folder per project, with the folder named exactly like the project. There are no grouping folders such as `src/api/` or `src/lib/`. The part after the dot already says what kind of project it is, so a second level would only repeat it.

For example (the product name here is illustrative):

- `src/<Product>.Api` - the web API
- `src/<Product>.Cli` - the command-line tool, including the database migration runner
- `src/<Product>.Notices` - a class library for notifications, referenced by the API

## Test projects

Each project that has automated tests gets one test project, named after the project it tests with a `.Tests` suffix, in `tests/` rather than `src/`. Not every project has one: a command-line tool or a thin host may be verified by hand instead.

- `tests/<Product>.Api.Tests`
- `tests/<Product>.Notices.Tests`

By-hand verification scripts, the steps a person follows to check something no automated test can, live in `tests/manual/`, one folder per subject, each with a `README.md` that holds the shared procedure.

## Namespaces

Namespaces follow folders. A class in `src/<Product>.Api/Certification/Plans/` belongs to the namespace `<Product>.Api.Certification.Plans`. Inside a project, group code by feature area (`Certification`, `Learning`, `Notification`) rather than by kind (`Controllers`, `Services`, `Models`), so everything a feature needs sits in one folder.

## Customer brand names

CMDS is the product's customer brand, and a brand can change. Keep it out of project names, namespaces, and assembly names, where a rename would touch every file.
