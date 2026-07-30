# Release Notes Generation Prompt

Reusable Claude prompt for drafting per-release notes in the same style as `docs/docs/changelog/version-26-3.md`. Paste the body below into a fresh conversation, fill in the placeholders, and let Claude work.

---

## Prompt

You are drafting release notes for the InSite platform. The output is a single Markdown file named `version-<MAJOR>-<MINOR>.md` placed in `C:\base\repo\cmds-app\docs\docs\changelog\`. Match the style and structure of the prior file `C:\base\repo\cmds-app\docs\docs\changelog\version-26-3.md` exactly — read it before writing anything new.

### Inputs you will be given

- **Previous release tag** — e.g. `release/v26.2`
- **New release tag** — e.g. `release/v26.3`
- **Live deploy date and time** — e.g. `June 10, 2026 at 8:00 PM MDT`
- **Demo deploy date** (optional) — used to update `release-notes.md`
- **Release classification** — `major` or `minor`
- **Headline changes** — 2–5 bullet points provided by the release manager. These are the human-curated themes; do not invent them from commits.
- **Source repository root** — defaults to `C:\base\repo\insite\code`
- **Docs repository root** — defaults to `C:\base\repo\cmds-app\docs`
- **Unused-by-CMDS page list** — defaults to `C:\base\repo\cmds-app\platform\tmp\analysis\unused-actions.csv` (columns: `ActionUrl`, `ControllerPath`). Every `.aspx` whose path appears here is excluded from CMDS-facing counts and the Modified Screens table. The file is a generated artifact, not committed. Regenerate it before each release from the production IIS logs at `C:\base\srv\host\e03\Production\logs\iis\W3SVC103`:

```powershell
cd C:\base\repo\cmds-app\platform
dotnet run --project src/Spark.Cli -- analyze-ui-usage --since <YYYY-MM-DD> --until <YYYY-MM-DD> --csv tmp\analysis\unused-actions.csv
```

  The command reads the same log directory and the routing table at `C:\base\repo\insite\code\db\routing.csv`. Related helper scripts live in `C:\base\repo\cmds-app\platform\tools\` (`analyze-iis-usage.ps1` for the raw hit inventory, `generate-delete-actions-sql.ps1` and `remove-unused-aspx.ps1` for cleanup).

  **Refresh the routing table first.** `routing.csv` is generated, and a stale copy silently drops pages from these notes. Regenerate it, along with `config\security\routes.json` (the source of the Screen labels), before running the usage analysis:

```powershell
cd C:\base\repo\insite\code\source\InSite.Maintenance\bin\Debug
.\InSite.Maintenance.exe permissions --code-path C:\base\repo\insite\code --output-path C:\base\repo\insite\code
```

### Data to gather

Run the following inside the source repo and use the results to fill the **Business Summary** numbers.

```powershell
$prev = "release/v26.2"; $next = "release/v26.3"
git log --oneline "$prev..$next" -- source/ | Measure-Object -Line
git shortlog -sn "$prev..$next" -- source/
git diff --shortstat "$prev..$next" -- source/
git diff --name-only "$prev..$next" -- source/ > changed-files.txt
```

Derive:

- Commit count (from `git log`)
- Distinct author count (from `git shortlog`)
- Files changed under `source/` (line count of `changed-files.txt`)
- Lines added / deleted under `source/` (from `--shortstat`)
- CMDS contribution share by commit count — match author names against the known CMDS team and report as a rounded percentage
- Count of `.sql` files under `source/<schema-upgrade-folder>/` that run on deploy
- **Page count for the "User-facing impact" paragraph** — count unique `.aspx` pages in the diff AFTER excluding any whose normalized path (lowercase, with `source/InSite.UI/` prefix stripped, `.aspx.cs`/`.aspx.vb` suffix replaced with `.aspx`) matches a `ControllerPath` in `unused-actions.csv` (normalize CSV entries the same way: drop the `~/` prefix, lowercase). Report total, markup-only-touched, code-behind-only-touched, and pages where both changed.

### How to build the Modified Screens table

1. From `changed-files.txt`, filter to `.aspx`, `.ascx`, and `.aspx.cs` / `.ascx.cs` under `source/InSite.UI/UI/`.
2. **Drop pages not used by CMDS.** Normalize each `.aspx` path to lowercase, strip the `source/InSite.UI/` prefix, and collapse `.aspx.cs`/`.aspx.vb` to `.aspx`. Drop the page if that key matches a `ControllerPath` (also normalized: `~/` stripped, lowercase) in `unused-actions.csv`. Excluded pages never appear in the Modified Screens table and are NOT counted in the headline stats.
3. Classify each remaining page:
   - **Markup change** if the `.aspx` or `.ascx` file itself changed.
   - **Code-behind change** if the `.cs` partner file changed.
   - **Both** if both did.
4. Look up the public URL for each `.aspx` path using `C:\base\repo\insite\code\config\security\routes.json` (it maps `ControllerPath` like `~/UI/Admin/...` to the clean action URL). If no entry exists, omit the page from the table and log it in a `# Unmapped` comment list at the bottom of your scratchpad — do not guess URLs.
5. Group rows under the section headings used in `version-26-3.md`:
   - `Specific to CMDS` — any URL starting with `ui/cmds/`
   - `Administrators - <Area>` — by the segment after `ui/admin/` (Accounts, Assessments, Contacts, Events, Learning / Programs, Tools, etc.)
   - `Users / Learners` — `ui/portal/*`, `ui/lobby/*`, `ui/home`, etc.
6. The **Screen** column is a short human-readable label (sentence case, no trailing period). Derive from the page title in the `.aspx` markup if present; otherwise from the URL segments.
7. Sort rows alphabetically by URL within each section.
8. Report the total non-CMDS exclusion count in the "User-facing impact" paragraph: `(<N> of these pages are **not** used by CMDS and are omitted from these release notes.)` where `<N>` is the data-row count of the `unused-actions.csv` you generated for this release (exclude the header row). Recount it every release - the number moves with the `--since` / `--until` window, so do not carry forward the count from a previous release.

### How to build the Shared UI Component Changes section

1. From `changed-files.txt`, identify shared user controls (`.ascx`) and helper code (e.g. `source/InSite.UI/**/Controls/`, `source/InSite.Common/`).
2. For each meaningful change, write one bullet describing what the component does and where it is used. Read the file's code comments and the surrounding folder name; do not invent functions.
3. Order: CMDS-specific shared components first, then platform-wide.

### Output structure (must match exactly)

```
# Version <MAJOR>.<MINOR>

This update to the Live environment is scheduled for <DATE> at <TIME>.

## Business Summary

**Scope.** This is a <major|minor> release.

It includes <N> code-change commits from <N> developers over multiple weeks, affecting <N> files under `source/`.

<N> lines of code added, <N> lines deleted within `source/`.

~<N>% of code changes (by commit count) were contributed by the CMDS team, spanning <one-line description of where>.

**User-facing impact.** The overall platform contains <N> web pages. (<N> of these pages are **not** used by CMDS and are omitted from these release notes.)

<N> pages modified directly, with <N> having visible markup changes and <N> having code-behind logic changes (<N> pages had both). (Counts exclude pages listed in `unused-actions.csv`.)

Hundreds more pages potentially affected indirectly via shared helper code.

<N> database upgrade scripts run on deploy, altering schema and data - irreversible without backup and restore.

**Headline changes.**

- <bullet 1>
- <bullet 2>
- ...

## Technical Details

Here is a list of changes, based on differences between version <PREV> and <NEW> in the source code repository.

This is the command used to identify differences:

`git diff --name-only release/v<PREV>..release/v<NEW>`

### 1. Modified Screens

These screens had their markup or code-behind changed. Every URL below should be retested.

> Screens that are not used by CMDS are omitted from the CMDS-specific section, but are listed below for completeness.

#### Specific to CMDS
| Screen | URL |
|---|---|
| ... | ... |

#### Administrators - <Area>
... etc

#### Users / Learners
... etc

### 2. Shared UI Component Changes - Pages to Retest by Module

Shared components used by multiple URLs affect multiple screens.

Here is a list of areas to smoke-test and ensure no unexpected side-effects from changes to shared components.

- <component 1 — what it does, where it is used>
- ...
```

### Style rules

- Sentence case for screen labels, section headings, and bullet text — not Title Case.
- No trailing periods on table cells, bullets that are fragments, or short labels.
- Full sentences in the Business Summary keep their periods.
- Use backticks around URLs in tables and around `git` commands.
- Use `&` em-dash `-` for compound section names (`Administrators - Accounts`) to match `version-26-3.md` exactly.
- Numbers: digits, no thousands separators in counts under 1000; comma separators above (e.g. `13,858`).
- Do not include a "Risk" subsection — `version-26-3.md` dropped it.
- Do not invent screens, components, or headline changes. If a URL cannot be resolved or a component's purpose is unclear, list it under a trailing `<!-- Needs review -->` HTML comment block at the bottom for the release manager to triage.

### After writing the file

1. Update `C:\base\repo\cmds-app\docs\docs\changelog\release-notes.md`:
   - Move the previous **Upcoming** block to **Current** with the actual Live date.
   - Add a new **Upcoming** block for the next planned version (ask if dates aren't provided).
2. Stop. Do not commit. Print the diff summary and wait for human review.

### What not to do

- Do not run a code review or critique the changes — these notes are a release log, not a PR review.
- Do not summarize commits one-by-one. The summary is statistical + a few human-chosen headlines.
- Do not pull in changes outside `source/` (build scripts, docs, planning) into the page counts.
- Do not guess at URLs missing from `routes.json`.

---

## Notes for the release manager

- The **Headline changes** bullets are the only narrative content. Curate them yourself from the merged PRs and major-feature tickets — Claude cannot reliably pick these from commit subjects.
- Verify the CMDS-team author list before each release; the contribution percentage depends on it.
- If a release introduces a new top-level URL area (e.g. `ui/cmds/something-new/`), add a new `#### Specific to CMDS - <Area>` subsection to keep the table readable.
