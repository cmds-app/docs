# Release notes generation prompt

Reusable Claude prompt for drafting per-release notes in the same style as the most recent file in `docs/changelog/`. Paste the body below into a fresh conversation, fill in the placeholders, and let Claude work.

## Prompt

You are drafting CMDS release notes. There are two outputs:

- **Published notes.** A single Markdown file named `version-<MAJOR>-<MINOR>.md` in `C:\base\repo\cmds-app\docs\docs\changelog\`. This is customer-facing. Match the structure and voice of the most recent prior file (for example `version-26-4.md`) exactly, and read it before writing anything new.
- **Internal summary.** A Markdown file named `version-<MAJOR>-<MINOR>-internal.md` in `C:\base\repo\cmds-app\docs\tmp\release-notes\`. This holds the statistics, recommended highlights with their sources, and anything that needs review. The docs repo is public, and `tmp/` is gitignored, so nothing in this file is ever published. Never put its content in the published notes.

### Inputs you will be given

- **Previous release branch** - e.g. `release/v26.4`
- **New release branch** - e.g. `origin/release/v26.5` (use the remote ref, or pull first; a local release branch can lag the remote)
- **Live deploy date and time** - e.g. `October 7, 2026 at 8:00 PM MDT`
- **Demo deploy date** (optional) - used to update `release-notes.md`
- **Release classification** - `major` or `minor`
- **CMDS team authors** - the git author names counted as the CMDS team, for the contribution share; defaults to `Daniel Miller`
- **Usage window** - the `--since` / `--until` dates for the IIS usage analysis; defaults to the 12 months ending the day before the run, so pages used only once a year (annual reports, yearly recertification) still count as used
- **Source repository root** - defaults to `C:\base\repo\insite\code`
- **Docs repository root** - defaults to `C:\base\repo\cmds-app\docs`

### Prerequisites

The source repository has two code trees, and both are in scope:

- `source/` - the legacy tree: Web Forms pages and controls in `source/InSite.UI`, and deploy-time SQL in `source/InSite.Maintenance/Scripts/Upgrades/v<MAJOR>.<MINOR>/`.
- `src/` - the newer tree: the React SPA in `src/ui/Shift.UI` (pages served under `client/`), plus the libraries and APIs in `src/library/` and `src/api/`.

Three generated artifacts must be fresh before you start. A stale copy silently drops pages from these notes, and nothing reports an error.

1. **Refresh the routing table.** `db/routing.csv` and `config/security/routes.json` (the source of the Web Forms page labels and URLs) are generated from the `settings.TAction` table in the local database, not from the code. If the local database has not had the new release's upgrade scripts applied, regeneration reproduces the previous release's routes (this happened in 26.5). In that case, read both files from the new release branch instead (`git show <new release branch>:config/security/routes.json`), and use that copy of `routing.csv` for the usage analysis too. To regenerate:

```powershell
cd C:\base\repo\insite\code\source\InSite.Maintenance\bin\Debug
.\InSite.Maintenance.exe permissions --code-path C:\base\repo\insite\code --output-path C:\base\repo\insite\code
```

2. **Refresh the IIS logs.** Confirm that `C:\base\srv\host\e03\Production\logs\iis\W3SVC103` contains logs through the end of the usage window. If the newest `u_ex<yymmdd>.log` is older than the `--until` date, stop and ask for a fresh copy. The source is `C:\Base\Data\Logs\Shift.UI\W3SVC103` on the InSite production server, `vm-prometheus`. It is an Azure VM reachable by RDP only (SMB on port 445 is closed, so a `\\vm-prometheus\C$` path fails with error 53). Connect with local drive C: redirected (Remote Desktop Connection, Local Resources, More, Drives), then run this in the RDP session, setting `/MAXAGE` to the date of the newest log you already have:

```powershell
robocopy "C:\Base\Data\Logs\Shift.UI\W3SVC103" "\\tsclient\C\base\srv\host\e03\Production\logs\iis\W3SVC103" "u_ex*.log" /MAXAGE:<yyyymmdd> /XO /R:2 /W:5 /NP
```

3. **Regenerate the unused-by-CMDS page list.** `C:\base\repo\cmds-app\platform\tmp\analysis\unused-actions.csv` (columns: `ActionUrl`, `ControllerPath`) lists every page with no production hits in the window. It is a generated artifact, not committed:

```powershell
cd C:\base\repo\cmds-app\platform
dotnet run --project src/Vesper.Cli -- analyze-ui-usage --since <YYYY-MM-DD> --until <YYYY-MM-DD> --csv tmp\analysis\unused-actions.csv
```

The command reads the log directory above and `db/routing.csv`. Related helper scripts live in `C:\base\repo\cmds-app\platform\tools\`, including `analyze-iis-usage.ps1` for the raw hit inventory.

### Data to gather (internal summary only)

Run the following in the source repo. Report `source/` and `src/` separately, then combined.

```powershell
$prev = "<previous release branch>"; $next = "<new release branch>"
foreach ($tree in "source/", "src/") {
    git log --oneline --no-merges "$prev..$next" -- $tree | Measure-Object -Line
    git shortlog -sn --no-merges "$prev..$next" -- $tree
    git diff --shortstat "$prev..$next" -- $tree
}
git diff --name-only "$prev..$next" -- source/ src/ > changed-files.txt
```

Derive:

- Commit count (non-merge) and distinct author count, per tree and combined
- Files changed, and lines added / deleted, per tree and combined
- CMDS contribution share by commit count, matching author names against the **CMDS team authors** input, as a rounded percentage
- Count of `.sql` files in `source/InSite.Maintenance/Scripts/Upgrades/v<MAJOR>.<MINOR>/` that run on deploy (test schemas such as `src/test/**/*.sql` do not count)
- Total pages on the platform: the data-row count of `db/routing.csv` (Web Forms) plus the number of routes in `src/ui/Shift.UI/src/routes/_formroutes/formRoutes.tsx` (React)
- Unused-by-CMDS count: the data-row count of the `unused-actions.csv` you generated for this release (exclude the header row). Recount it every release, because the number moves with the usage window.
- Modified-page counts after exclusions: total, markup-only, code-behind-only, both, and React

### How to build the updated pages list

**Web Forms pages (`source/`).**

1. From `changed-files.txt`, filter to `.aspx`, `.ascx`, and `.aspx.cs` / `.ascx.cs` under `source/InSite.UI/UI/`.
2. **Drop pages not used by CMDS.** Normalize each `.aspx` path to lowercase, strip the `source/InSite.UI/` prefix, and collapse `.aspx.cs` / `.aspx.vb` to `.aspx`. Drop the page if that key matches a `ControllerPath` in `unused-actions.csv` (normalized the same way: `~/` stripped, lowercase). Dropped pages never appear in the published notes. Pages added in this release (`git diff --name-status` shows `A`) have no production history, so never drop them for lack of usage.
3. Classify each remaining page for the internal summary: **markup** if the `.aspx` or `.ascx` changed, **code-behind** if the `.cs` partner changed, **both** if both did.
4. Look up the URL for each `.aspx` in `config/security/routes.json`, which maps a `ControllerPath` like `~/UI/Admin/...` to its clean action URL. If there is no entry, look for a `NavigateUrl` constant in the page's code-behind (e.g. `public const string NavigateUrl = "/ui/portal/learning/programs/request";`) and use that, noting it under **Needs review**. If neither exists, leave the page out of the published notes and list it under **Needs review** in the internal summary. Do not guess URLs.

**React pages (`src/`).**

5. From `changed-files.txt`, take files under `src/ui/Shift.UI/src/routes/` (excluding `test/`). Resolve each changed component to its route by following the `element` imports in `src/ui/Shift.UI/src/routes/_formroutes/formRoutes.tsx`. The URL is the route's `path` without the leading `/`, e.g. `client/admin/records/gradebooks/search`. Use the route's `title` as the starting point for the label.
6. Skip routes under `client/test/` and `client/react/`. They are developer scaffolding, not customer pages.
7. React pages are not in `routing.csv`, so `unused-actions.csv` cannot exclude them. Check the raw hit inventory (`analyze-iis-usage.ps1`) for the route path, with route parameters such as `:id` treated as wildcards. Include the page if it has hits in the usage window. If it has none, or the result is unclear, leave it out and list it under **Needs review**.

**Both trees.**

8. Group rows under the section headings used in the prior file:
   - `Specific to CMDS` - URLs starting with `ui/cmds/`
   - `Administrators - <Area>` - by the segment after `ui/admin/` or `client/admin/` (Accounts, Assessments, Contacts, Courses, Events, Learning / Programs, Reports, and so on). Web Forms and React pages for the same area share one section.
   - `Users / Learners` - `ui/portal/*`, `ui/lobby/*`, `ui/home`, and similar
9. The **Page** column is a short, plain-language label that a customer would recognize: sentence case, no trailing period. Read the page title in the `.aspx` markup or the React route `title`, then rewrite it for a reader who has never seen the code (e.g. `Write content`, `Launch a SCORM course`, `Active users (report)`).
10. Sort rows alphabetically by URL within each section.
11. The page count in the published opening paragraph is the number of rows across all tables.

### How to build the behind-the-scenes list

1. From `changed-files.txt`, identify shared code with a visible effect on more than one page:
   - Web Forms user controls (`.ascx`) and helpers, e.g. `source/InSite.UI/**/Controls/`
   - React shared components in `src/ui/Shift.UI/src/components/`, `layouts/`, and `hooks/`
   - Library and API changes in `src/library/` and `src/api/` only when they change something a user can see or an integration depends on
2. Write each bullet as a short, customer-facing noun phrase naming the area that changed (e.g. `Course search criteria and results`, `Date pickers and inline editors`), not the component or file name. Read the code comments and the folder names to work out what each component does; do not invent functions.
3. Combine related components into one bullet. Aim for 10 to 20 bullets.
4. Order: CMDS-specific areas first, then platform-wide.
5. List each bullet's underlying files in the internal summary, so a tester can find them.

### How to recommend highlights

You recommend the highlights; the release manager approves them during review.

1. List the merged pull requests in the release: `git log --merges --format='%s' "$prev..$next"` gives the PR numbers.
2. For each, read the title and body: `gh pr view <number> --repo insite/code --json title,body`. Titles carry the ticket key and type, e.g. `TEC-1182 (Feature) Require the Scoop signature header on the SCORM progress callback`.
3. Group related PRs into themes. Keep only themes that a CMDS customer can see or would care about: new pages or reports, changed workflows, sign-in and security changes, integration changes. Drop internal refactors, test work, and one-off fixes unless a fix resolves a problem customers reported.
4. Pick the 3 to 5 strongest themes. Write each as one plain-language sentence fragment with no trailing period, in the voice of the prior file's Highlights.
5. Put them in the published notes. In the internal summary, list each highlight with its PR numbers and ticket keys, then list the runner-up themes you left out, so the release manager can swap one in.

### Published notes structure (must match exactly)

```
# Version <MAJOR>.<MINOR>

This update to the Live environment is scheduled for <DATE> at <TIME>.

Version <MAJOR>.<MINOR> is a <major|minor> release. It updates <N> pages across the platform, along with several shared components used throughout CMDS. These notes cover only the pages and features used by CMDS.

## Highlights

- <highlight 1>
- <highlight 2>
- ...

## Updated pages

The following pages were updated in this release. If you use any of them regularly, you may notice small improvements to layout or behaviour.

### Specific to CMDS

| Page | URL |
|---|---|
| ... | `ui/cmds/...` |

### Administrators - <Area>

| Page | URL |
|---|---|
| ... | ... |

### Users / Learners

| Page | URL |
|---|---|
| ... | ... |

## Behind-the-scenes improvements

This release also improves shared components that appear on many pages. You may notice small changes in these areas:

- <area 1>
- ...

If you have questions about anything in this release, reach out to CMDS Administration (<admin_cmds@keyera.com>).
```

The opening line says "is scheduled for" until the release goes Live. After it goes Live it says "This update was released to the Live environment on <DATE> at <TIME>." Leave the tense as "is scheduled for" when drafting.

### Internal summary structure

```
# Version <MAJOR>.<MINOR> - internal summary

Not for publication. Generated <YYYY-MM-DD> from <prev>..<next>.

## Statistics

| Measure | source/ | src/ | Combined |
|---|---|---|---|
| Commits (non-merge) | ... | ... | ... |
| Authors | ... | ... | ... |
| Files changed | ... | ... | ... |
| Lines added | ... | ... | ... |
| Lines deleted | ... | ... | ... |

- CMDS team share by commit count: ~<N>% (<authors counted>)
- Database upgrade scripts run on deploy: <N> (irreversible without backup and restore)
- Pages on the platform: <N> (<N> Web Forms, <N> React); <N> not used by CMDS in <since>..<until>
- Pages modified and used by CMDS: <N> (<N> markup only, <N> code-behind only, <N> both, <N> React)

## Recommended highlights

- <highlight> - PR #<n> (TEC-<n>), ...
- Runner-up: <theme> - PR #<n>, ...

## Behind-the-scenes sources

- <area> - <files>

## Needs review

- <unmapped URL, React route with unclear usage, or component whose purpose is unclear>
```

### Style rules

- Sentence case for page labels, headings, and bullets. Not Title Case.
- No trailing periods on table cells, highlight bullets, or behind-the-scenes bullets (they are fragments). Full sentences keep their periods.
- Backticks around every URL in the tables.
- Hyphens only (`Administrators - Accounts`). No em dashes, en dashes, or `→`.
- Canadian spelling in prose (behaviour, colour, centre, cancelled), keeping `-ize` (organize, recognize). Screen labels that already use a US spelling in the product, such as `Program enrollments`, keep the product's spelling.
- Numbers: digits; comma separators at 1,000 and above (e.g. `13,858`).
- No statistics, commit counts, author names, ticket keys, or PR numbers in the published notes.
- Do not invent pages, components, or highlights. Anything uncertain goes under **Needs review** in the internal summary.

### After writing the files

1. Update `docs/changelog/release-notes.md`:
   - Change the **Upcoming** block's draft line from `_coming soon_` to a link to the new file.
   - When the release has gone Live: move the **Current** block into **Previous releases** (`- **Version <X>** - released <date> ([release notes](version-<x>.md))`), move **Upcoming** to **Current** with the actual Live date, and add a new **Upcoming** block for the next version. Take its dates from `release-dates.md`, or ask if they are not listed.
2. When the release has gone Live, update `docs/changelog/release-dates.md`: move the bold **(current)** marker to the new release row.
3. Add the new file to the `Changelog` nav in `mkdocs.yml`, above the previous version.
4. Stop. Do not commit. Print a diff summary and the path to the internal summary, and wait for human review.

### What not to do

- Do not run a code review or critique the changes. These notes are a release log, not a PR review.
- Do not summarize commits or PRs one by one.
- Do not count changes outside `source/` and `src/` (build scripts, config, docs, planning) in the statistics.
- Do not guess URLs missing from `routes.json` or `formRoutes.tsx`.

## Notes for the release manager

- Review the recommended highlights against the internal summary's sources and runner-ups before approving. They are recommendations, not decisions.
- Confirm the CMDS team author list before each run. The contribution share depends on it.
- If a release introduces a new top-level URL area (e.g. `ui/cmds/something-new/`), add a `### Specific to CMDS - <Area>` subsection to keep the tables readable.
