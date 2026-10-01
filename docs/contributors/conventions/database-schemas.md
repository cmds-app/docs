# Database naming conventions

Naming conventions to help every contributor speak the same schema. The database is PostgreSQL, and PostgreSQL folds unquoted names to lowercase, so every name is lowercase snake case. Upper-case names force quoting everywhere they are used, which is why they are [strongly discouraged](https://wiki.postgresql.org/wiki/Don't_Do_This#Don.27t_use_upper_case_table_or_column_names).

## Schemas

A schema groups the tables for one area of the product. Its name is a singular noun:

- `public` - the core tables every area shares, such as `company`, `account`, and `migration`
- `integration` - copies of data from external systems, and the runs that keep them in sync
- `learning` - course enrolments and progress
- `notice` - notification rules, subscribers, and deliveries

## Tables

- A table name is singular: `company`, not `companies`; `course_enrolment`, not `course_enrolments`.
- A table that mirrors an external system starts with the system's name: `google_country`, `workday_employee`, `vimeo_video`. The prefix tells you the data is a copy, and where the source of truth lives.
- Avoid a bare reserved word such as `user` or `group`. A prefix or a more specific noun (`account`, `team`) avoids quoting.

## Columns

Every column starts with the name of its table, apart from the foreign keys described below. In the `company` table the columns are `company_id`, `company_name`, `company_handle`, and `company_started_at`, never `id`, `name`, or `started_at`.

You'd expect this to be noise, but it pays for itself in a join. With the prefix, a column name means the same thing in every query and every result set, no two tables share a column name by accident, and a search for `company_handle` finds every place that value is read or written.

- **Primary key.** `<table>_id`. A new table uses a `uuid` that defaults to `gen_random_uuid()`. A mirror table keeps the key the source system issued, with its type, and a table filled from another system (such as `company`, pushed by partition registration) takes the id it is given, so it has no default.
- **Foreign key.** A column that points at another table takes the name of the key it references, such as `company_id` in `course_enrolment`. When the role matters, or a table points at the same table twice, a role prefix says which is which: `learner_user_id`.
- **Handle.** A URL-friendly identifier token is called a handle (`company_handle`), in the database, the code, the API, and the UI alike.

Two tables break the prefix rule on purpose. `integration.google_translation` has one column per language code (`en`, `fr`, `de`), because the code is the column. `public.migration` belongs to the migration runner, and its two columns (`filename`, `applied_at`) predate the rule. Two more break it by accident and are renamed when next touched: `public.certificate_verification` and the `event_*` columns of `notice.delivery_event`.

### Suffixes and data types

| Suffix | Type | Example |
| :----- | :--- | :------ |
| `_id` | `uuid` | `course_enrolment_id` |
| `_at` | `timestamp with time zone` | `course_enrolment_completed_at` |
| `_date` | `date` | `vimeo_video_day_date` |
| `_is_<adjective>`, `_can_<verb>`, `_has_<noun>` | `boolean` | `subscriber_is_active`, `account_can_report` |
| `_count` | `integer` | `course_enrolment_restart_count` |
| `_handle` | `character varying(100)`, or `text` in a mirror | `company_handle` |
| `_url` | `character varying(254)`, or `text` in a mirror | `company_website_url` |

A value with both a date and a time is always `timestamp with time zone`, so its meaning never depends on the server's time zone. A date with no time is `date`. A mirror column keeps the source system's type where that type matters to the copy. Older names that predate a rule (`account_api_enabled`, a `_date` column that holds a timestamp) are fixed when next touched, not on sight.

Audit timestamps follow the same prefix rule: `course_enrolment_created_at` and `course_enrolment_updated_at`.

## Constraints and indexes

A constraint or index name starts with its kind, then the table:

| Prefix | Kind | Example |
| :----- | :--- | :------ |
| `pk_` | Primary key | `pk_company` |
| `fk_` | Foreign key | `fk_delivery_dispatch` |
| `uq_` | Unique constraint | `uq_course_enrolment_learner_course` |
| `ux_` | Unique index, such as a partial one a constraint cannot express | `ux_quad_member_active_email` |
| `ck_` | Check | `ck_vimeo_video_duration` |
| `ix_` | Index | `ix_google_province_google_country_code` |

## Migrations

Schema changes are hand-written SQL files in `db/migrations/`, named with a three-digit sequence and a short description: `126_create_learning_catalogue_setting.sql`. Each sequence number is used once. Two early numbers (`096` and `097`) were each used twice before this rule was enforced; they are applied and stay as they are. `db/migrations/` holds migration files only. The migration runner applies files in filename order, each in its own transaction, and records every applied file in `public.migration`.

- Never edit a migration that has been applied. Add a new one.
- Start each file with a comment that explains why the change is needed, not only what it does.
- After a migration, regenerate the schema artifacts with `db/export-schema.ps1`. It writes `db/schema.sql` and an ER diagram (`db/schema.dot` and `db/schema.svg`) covering every schema.
