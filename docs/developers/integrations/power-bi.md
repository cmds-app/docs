# Power BI

If you report on compliance in Power BI, you can pull the data straight from the CMDS API instead of exporting spreadsheets by hand. This page connects Power BI to the same compliance summary endpoint that the [worked example](../api/example.md) walks through, so read that page first if you have not called the API before.

## Why use the API?

A report built on an exported spreadsheet is out of date the moment someone downloads it. A report built on the API refreshes itself: Power BI calls the endpoint on a schedule and replaces the data each time, so every dashboard shows the latest snapshot without anyone copying files around.

## Before you start

You need the same three things as the worked example:

1. **A personal API secret.** An operator enables API access for your account, then you generate the secret on your account page. See [Authentication](../api/authentication.md).
2. **Report access.** The compliance summary is gated more tightly than the rest of the API. An operator grants it on the **Security > Accounts** page. Without it, every refresh fails with `403`.
3. **Your base address.** Use `https://test-api.cmds.app` while you build the report, and `https://api.cmds.app` once it is ready for production.

You also need Power BI Desktop, and the department ids you want to report on.

## Step 1: Open the Advanced Editor

The compliance summary is a `POST` request with a JSON body. The **From Web** dialog in Power BI only sends `GET` requests, so write the query in Power Query instead:

1. In Power BI Desktop, select **Get data > Blank query**.
2. In the Power Query Editor, select **Advanced Editor**.

## Step 2: Paste the query

Replace the contents of the editor with this query, then put your own secret and department id in the first lines:

```
let
    BaseUrl = "https://test-api.cmds.app",
    Secret = "vsk_test_your_secret_here",
    Body = [ departments = { "3f2504e0-4f89-41d3-9a0c-0305e82c3301" } ],

    Response = Web.Contents(
        BaseUrl,
        [
            RelativePath = "reporting/compliance-summary",
            Headers = [
                #"Authorization" = "Bearer " & Secret,
                #"Content-Type" = "application/json"
            ],
            Content = Json.FromValue(Body)
        ]
    ),

    Rows = Json.Document(Response),
    Table = Table.FromList(Rows, Splitter.SplitByNothing(), {"Row"}),
    Expanded = Table.ExpandRecordColumn(Table, "Row", {"department", "member", "primaryProfile", "measurement"}),
    Department = Table.ExpandRecordColumn(Expanded, "department", {"id", "name"}, {"Department id", "Department"}),
    Member = Table.ExpandRecordColumn(Department, "member", {"id", "name", "code"}, {"Member id", "Member", "Member code"}),
    Profile = Table.ExpandRecordColumn(Member, "primaryProfile", {"name"}, {"Primary profile"}),
    Measurement = Table.ExpandRecordColumn(Profile, "measurement", {"name", "score", "required", "satisfied", "expired", "notCompleted"}, {"Measurement", "Score", "Required", "Satisfied", "Expired", "Not completed"})
in
    Measurement
```

A few things to know about this query:

- **Adding `Content` makes it a `POST`.** `Web.Contents` sends a `GET` unless you give it a body.
- **`RelativePath` keeps the base address fixed.** Power BI can only refresh a query in the Power BI service when the base address in `Web.Contents` does not change, so keep the path in `RelativePath` rather than joining it onto the base address.
- **The body follows the same rules as the worked example.** Name at least one department, or name members together with the measurements you want. An unbounded request answers `400`. See [Bounding your request](../api/example.md#bounding-your-request) and the full list of [request fields](../api/example.md#request-fields).
- **The result is one table, with no paging.** The compliance summary returns every row in a single response, so you do not need a loop to collect pages.

Select **Done**. If Power BI asks how to connect, choose **Anonymous**: the secret travels in the `Authorization` header, not in a Power BI credential.

## Step 3: Shape and load the data

The query expands the nested JSON into columns: department, member, primary profile, and the measurement with its score and counts. Two details from the worked example matter when you build visuals on top of it:

- **`Score` runs from 0 to 1.** Format the column as a percentage. It is empty when a score does not apply to the row.
- **Group by the measurement name, not its key.** The key is not a stable identifier, which is why the query keeps `name` and leaves `key` out.

Select **Close & Apply** to load the table into your report.

## Step 4: Publish and schedule a refresh

When the report is ready, generate a personal secret on Live (a Test secret does not authenticate there), change `BaseUrl` to `https://api.cmds.app` and `Secret` to the Live secret, publish it to the Power BI service, and set up a scheduled refresh on the semantic model. When the service asks for data source credentials, choose **Anonymous** again.

The report reads the same snapshot the API does, so there is little point refreshing it more often than that snapshot changes. A daily refresh suits most compliance dashboards.

## Keeping the secret safe

In this query the secret is stored inside the report. Anyone who can open the `.pbix` file or edit the semantic model can read it, and with it call the API as you. Treat the file as you would the secret itself:

- **Share the report, not the file.** Publish to the Power BI service and share the report from there, rather than sending the `.pbix` around.
- **Know what stops a refresh.** A personal secret has no expiry date, so a scheduled refresh keeps working until the secret is replaced or revoked, or an operator removes your API or report access. Generating a new secret replaces the old one immediately, so update the query in the same sitting.
- **Revoke on exposure.** If the file leaves your control, revoke the secret on your account page and generate a new one.

## Need help?

If you get stuck, reach out to our support team. We're happy to help.
