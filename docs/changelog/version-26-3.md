# Version 26.3

This update to the Live environment is scheduled for June 10, 2026 at 8:00 PM MDT.

## Business Summary

**Scope.** This is a major release.

It includes 208 code-change commits from 4 developers over multiple weeks, affecting 1,731 files under `source/`.

13,858 lines of code added, 9,737 lines deleted within `source/`.

~49% of code changes (by commit count) were contributed by the CMDS team, spanning CMDS pages and partition/Hub integration.

**User-facing impact.** The overall platform contains 870 web pages. (415 of those forms are **not** used by CMDS and are omitted from these release notes.)

81 pages modified directly, with 41 having visible markup changes and 76 having code-behind logic changes (36 pages had both).

Hundreds more pages potentially affected indirectly via shared helper code.

20 database upgrade scripts run on deploy, altering schema and data - irreversible without backup and restore.

**Headline changes.**

- Platform documentation is now consolidated in the CMDS Docs repository (GitHub)
- Static web-accessible content is now consolidated in the CMDS Assets repository (GitHub)
- Application features and functions implementated specifically for CMDS partners are now consolidated in the CMDS Hub (authentication is via SAML)
- Platform-wide team memberships for invoicing contacts per organization

## Technical Details

Here is a list of changes, based on differences between version 26.2 and 26.3 in the source code repository.

This is the command used to identify differences:

`git diff --name-only release/v26.2..release/v26.3`

### 1. Modified Screens

These screens had their markup or code-behind changed. Every URL below should be retested.

> Screens that are not used by CMDS are omitted from the CMDS-specific section, but are listed below for completeness.

#### Specific to CMDS

| Screen | URL |
|---|---|
| Bulk-assign time-sensitive safety certificates | `ui/cmds/admin/achievements/credentials/assign` |
| Edit achievement | `ui/cmds/admin/achievements/edit` |
| View achievement references | `ui/cmds/admin/achievements/view-references` |
| Edit organization | `ui/cmds/admin/organizations/edit` |
| Training completions (report) | `ui/cmds/admin/reports/training-completions` |
| Training expiry dates (report) | `ui/cmds/admin/reports/training-expiry-dates` |
| Training history by worker (report) | `ui/cmds/admin/reports/training-history-by-worker` |
| Create competency profile | `ui/cmds/admin/standards/profiles/create` |
| Edit competency profile | `ui/cmds/admin/standards/profiles/edit` |
| Competency profile outline | `ui/cmds/admin/standards/profiles/outline` |
| Search competency profiles | `ui/cmds/admin/standards/profiles/search` |

#### Administrators - Accounts

| Screen | URL |
|---|---|
| Search organizations | `ui/cmds/admin/organizations/search` |

#### Administrators - Assessments

| Screen | URL |
|---|---|
| Assessments home | `ui/admin/assessments/home` |
| Download assessment bank | `ui/admin/assessments/banks/download` |
| Print assessment bank | `ui/admin/assessments/banks/print` |
| Print assessment form | `ui/admin/assessments/forms/print` |

#### Administrators - Contacts

| Screen | URL |
|---|---|
| Create group membership | `ui/admin/contacts/groups/create-membership` |
| Create person membership | `ui/admin/contacts/people/create-membership` |
| Edit person | `ui/admin/contacts/people/edit` |
| Send a welcome email | `ui/admin/contacts/people/send-email` |

#### Administrators - Events

| Screen | URL |
|---|---|
| Edit class event | `ui/admin/events/classes/outline` |

#### Administrators - Learning / Programs

| Screen | URL |
|---|---|
| Assign learners to a program | `ui/admin/learning/programs/enrollments/assign` |
| Edit achievement on a program | `ui/admin/learning/programs/modify-achievement` |
| Publish a program | `ui/admin/learning/programs/modify-publication` |

#### Administrators - Tools

| Screen | URL |
|---|---|
| Tools | `ui/admin/tools` |

#### Users / Learners

| Screen | URL |
|---|---|
| Sign in | `ui/lobby/signin` |
| Attempt a quiz | `ui/portal/assessments/attempts/answer` |
| View / edit a person record | `ui/portal/contacts/people/outline` |
| Launch a SCORM 1.2 activity | `ui/portal/learning/catalog` |
| Launch a SCORM Tin Can activity (e.g. Hydrates) | `ui/portal/learning/catalog` |
| Organization orientations | `ui/portal/learning/organizations-orientations` |
| View my profile | `ui/portal/profile` |
| Switch organization | `ui/portal/security/organizations` |

### 2. Shared UI Component Changes - Pages to Retest by Module

Shared components used by multiple URLs affect multiple screens.

Here is a list of areas to smoke-test and ensure no unexpected side-effects from changes to shared components.

- Achievement search criteria and results (CMDS)
- Achievement list editor (used across CMDS achievement pages)
- Bulk tools to select and assign achievements
- Profile owner selector (renamed from `ProfileHierarchy`; replaces `ProfileVisibilitySelector`)
- Reusable organization scope selector (now drives credential Assign and Achievement search; CMDS)
- Invoicing contacts control (CMDS)
- Survey/form submission search criteria and results
- Contact group role grid
- Course search results and activity controls
- Class event registration grid
- Credential search criteria and results
- Programs publication setup
- Mailout failure search results
