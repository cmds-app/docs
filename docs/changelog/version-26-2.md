# Version 26.2

The update to the Live environment was released on May 6, 2026 at 8:00 PM MDT.

## Business Summary

**Scope.** This is a major release.
It includes 370 code-change commits from 3 developers over multiple weeks, affecting 813 files.
32,795 lines of code added, 8,144 lines deleted.
23% of code changes were contributed by the CMDS team.

**User-facing impact.** The overall platform contains 1,868 web pages.
152 pages modified directly, with 71 with visible layout changes, and another 81 with behind-scenes logic changes.
Hundreds more pages potentially affected indirectly via shared helper code.
18 database upgrade scripts run on deploy, altering schema and data - irreversible without backup and restore.

**Risk.** This is a major release. Recommendation: Full test/review.

## Technical Details

Here is a list of changes, based on differences between version 26.1 and 26.2 in the source code repository.

This is the command used to identify differences:

`git diff --name-only release/v26.1..release/v26.2`

### 1. Modified Screens

These screens had their markup or code-behind changed. Every URL below should be retested.

> Screens that are not used by CMDS are omitted.

#### Specific to CMDS

| Screen | URL |
|---|---|
| Bulk-assign time-sensitive safety certificates | `ui/cmds/admin/achievements/credentials/assign-certificate` |
| Edit achievement | `ui/cmds/admin/achievements/edit` |
| Department profile details (report) | `ui/cmds/admin/reports/department-profile-details` |
| Training completions (report) | `ui/cmds/admin/reports/training-completions` |
| Training expiry dates (report) | `ui/cmds/admin/reports/training-expiry-dates` |
| Validate competency self-assessment | `ui/cmds/portal/validations/competencies/submit` |

#### Administrators - Assessments

| Screen | URL |
|---|---|
| Publish assessment form (quiz) | `ui/admin/assessments/forms/publish` |
| Edit assessment question (quiz question) | `ui/admin/assessments/questions/change` |

#### Administrators - Contacts

| Screen | URL |
|---|---|
| View and edit reporting lines | `ui/admin/contacts/people/create-user-connection` |
| Send a welcome email | `ui/admin/contacts/people/send-email` |

#### Administrators - Events

| Screen | URL |
|---|---|
| Edit class event | `ui/admin/events/classes/outline` |
| Search class event registrations | `ui/admin/events/registrations/search` |

#### Administrators - Programs

| Screen | URL |
|---|---|
| Delete program | `ui/admin/learning/programs/delete` |
| Edit program (change name or description) | `ui/admin/learning/programs/describe` |
| Assign learners to a program | `ui/admin/learning/programs/enrollments/assign` |
| Edit achievement | `ui/admin/learning/programs/modify-achievement` |
| Assign a catalog to a program | `ui/admin/learning/programs/modify-catalog` |
| Publish a program | `ui/admin/learning/programs/modify-publication` |
| Edit program settings per achievement | `ui/admin/learning/programs/modify-settings` |
| Add achievements to a program | `ui/admin/learning/programs/tasks/assign` |

#### Administrators - Messages

| Screen | URL |
|---|---|
| Edit the content for a message | `ui/admin/messages/content` |

#### Users/Learners

| Screen | URL |
|---|---|
| View the home page | `ui/home` |
| Sign out | `ui/lobby/signout` |
| Attempt a quiz | `ui/portal/assessments/attempts/answer` |
| View classes open for registration | `ui/portal/events/classes/outline` |
| Register for a class | `ui/portal/events/classes/register-employee` |
| View my education and training | `ui/cmds/portal/achievements/credentials/search` |
| View my training plan | `ui/portal/learning/plan` |
| Start a course | `ui/portal/learning/course` |
| View my profile | `ui/portal/profile` |

### 2. High-Impact Page Layout Changes

These changes affect MANY forms. Smoke-test a representative page in each bucket below.

- **Portal Layout** - every `ui/portal/*` page. Spot-check `ui/portal/home`, `ui/portal/learning/catalog`, `ui/portal/events/calendar`, `ui/portal/profile`.
- **Admin Layout** - every `ui/admin/*` page. Spot-check `ui/admin/home`, `ui/admin/assessments/home`, `ui/admin/records/home`, `ui/admin/workflow/home`.

### 3. Shared UI Component Changes - Pages to Retest by Module

Shared components used by multiple URLs affect multiple screens. Here is a list of screens to smoke-test and ensure no unexpected side-effects from changes to shared components.

- Add, edit, and delete activities in a course
- Search for class event registrations
- Search for achievements
- Search all user certificates on the My Orientations portal
- Submit a class event registration form
