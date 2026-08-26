# Version 26.4

This update was released to the Live environment on August 5, 2026 at 8:00 PM MDT.

Version 26.4 is a major release. It updates 71 pages across the platform, along with several shared components used throughout CMDS. These notes cover only the pages and features used by CMDS.

## Highlights

- Two new reports are available to administrators, covering program achievements and program enrollments
- Person records, memberships, and reporting-line connections have been reorganized so a person's history stays together
- Course search offers more filtering, and results show the status of each course

## Updated pages

The following pages were updated in this release. If you use any of them regularly, you may notice small improvements to layout or behavior.

### Specific to CMDS

| Page | URL |
|---|---|
| Active users (report) | `ui/cmds/admin/reports/active-users` |
| Training completions (report) | `ui/cmds/admin/reports/training-completions` |
| Training expiry dates (report) | `ui/cmds/admin/reports/training-expiry-dates` |
| Training history by worker (report) | `ui/cmds/admin/reports/training-history-by-worker` |
| Compare competency profiles | `ui/cmds/admin/standards/profiles/compare` |
| Edit competency profile | `ui/cmds/admin/standards/profiles/edit` |
| Create a person record | `ui/cmds/admin/users/create` |
| Send an email | `ui/cmds/admin/users/send` |
| Add education and training | `ui/cmds/portal/achievements/credentials/create` |
| Edit education and training | `ui/cmds/portal/achievements/credentials/edit` |

### Administrators - Accounts

| Page | URL |
|---|---|
| Edit organization | `ui/admin/accounts/organizations/edit` |

### Administrators - Assessments

| Page | URL |
|---|---|
| Assessment bank outline | `ui/admin/assessments/banks/outline` |
| Change criteria filter | `ui/admin/assessments/criteria/change-filter` |
| Write content | `ui/admin/assessments/criteria/content` |
| Add assessment form | `ui/admin/assessments/forms/add` |
| Change form content | `ui/admin/assessments/forms/content` |
| Pre-publish form | `ui/admin/assessments/forms/prepublish` |
| Print form | `ui/admin/assessments/forms/print` |
| Publish or unpublish form | `ui/admin/assessments/forms/publish` |
| Rename form | `ui/admin/assessments/forms/rename` |
| Form workshop | `ui/admin/assessments/forms/workshop` |
| Add specification | `ui/admin/assessments/specifications/add` |

### Administrators - Contacts

| Page | URL |
|---|---|
| Contacts home | `ui/admin/contacts/home` |

### Administrators - Courses

| Page | URL |
|---|---|
| Courses home | `ui/admin/courses/home` |
| Manage a course | `ui/admin/courses/manage` |

### Administrators - Events

| Page | URL |
|---|---|
| Schedule a new class | `ui/admin/events/classes/create` |
| Modify class notifications | `ui/admin/events/classes/modify-notification` |
| Edit class event | `ui/admin/events/classes/outline` |
| Search class event registrations | `ui/admin/events/registrations/search` |

### Administrators - Learning / Programs

| Page | URL |
|---|---|
| Create catalog | `ui/admin/learning/catalogs/create` |
| Edit catalog | `ui/admin/learning/catalogs/edit` |
| Search catalogs | `ui/admin/learning/catalogs/search` |
| Create program | `ui/admin/learning/programs/create` |
| Edit program (change name or description) | `ui/admin/learning/programs/describe` |
| Duplicate program | `ui/admin/learning/programs/duplicate` |
| Assign learners to a program | `ui/admin/learning/programs/enrollments/assign` |
| Assign a catalog to a program | `ui/admin/learning/programs/modify-catalog` |
| Edit program settings per achievement | `ui/admin/learning/programs/modify-settings` |
| Program outline | `ui/admin/learning/programs/outline` |
| Add achievements to a program | `ui/admin/learning/programs/tasks/assign` |

### Administrators - Messages

| Page | URL |
|---|---|
| Message outline | `ui/admin/messages/outline` |

### Administrators - Registrations

| Page | URL |
|---|---|
| Edit class registration | `ui/admin/registrations/classes/edit` |

### Administrators - Reports

| Page | URL |
|---|---|
| Dashboards | `ui/admin/reports/dashboards` |
| Program achievements | `ui/admin/reports/program-achievements` |
| Program enrollments | `ui/admin/reports/program-enrollments` |

### Administrators - Security

| Page | URL |
|---|---|
| Security home | `ui/admin/security/home` |

### Administrators - Setup

| Page | URL |
|---|---|
| Setup home | `ui/admin/setup/home` |

### Administrators - Sites

| Page | URL |
|---|---|
| Modify page settings | `ui/admin/sites/pages/change-settings` |
| Change page setup | `ui/admin/sites/pages/change-structure` |

### Administrators - Tools

| Page | URL |
|---|---|
| Tools | `ui/admin/tools` |

### Users / Learners

| Page | URL |
|---|---|
| Register | `ui/lobby/register` |
| Sign in | `ui/lobby/signin` |
| Sign-in challenge | `ui/lobby/signin-challenge` |
| Multi-factor authentication challenge | `ui/lobby/signin-mfa` |
| Sign in with a social account | `ui/lobby/signin-social` |
| Start a quiz attempt | `ui/portal/assessments/attempts/start` |
| Add yourself to a class waiting list | `ui/portal/events/classes/add-to-waiting-list` |
| View classes open for registration | `ui/portal/events/classes/outline` |
| Register for a class | `ui/portal/events/classes/register` |
| Achievements on the home page | `ui/portal/home/achievements` |
| Launch a SCORM course | `ui/portal/integrations/scorm/launch` |
| Course catalogue | `ui/portal/learning/catalogue` |
| Start a course | `ui/portal/learning/course` |
| Organization orientations | `ui/portal/learning/organizations-orientations` |
| View my profile | `ui/portal/profile` |
| Download a certificate | `ui/portal/records/credentials/certificate` |

## Behind-the-scenes improvements

This release also improves shared components that appear on many pages. You may notice small changes in these areas:

- Competency profile search criteria and results
- Achievement criteria selection on competency profiles
- Profile owner selection on competency profiles
- Person details on CMDS pages
- Training report criteria
- The CMDS home page
- Education and training search results and certificate entry
- Assessment form details, content, and page alerts
- Assessment criteria entry
- Assessment specifications and section setup
- Question printing, in compact, internal, and external layouts
- Course search criteria and results
- Course outlines, including activities, module structure, and prerequisites
- Class notifications and class event registration search
- Catalog search criteria and results
- Program task lists and grids
- Credential search criteria
- Report criteria for program achievements and program enrollments
- Admin navigation and profile picture upload

If you have questions about anything in this release, reach out to our support team.
