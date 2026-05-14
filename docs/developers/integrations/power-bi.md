# Power BI

First steps on building reports from your LMS data.

Power BI is Microsoft's business intelligence and data visualization platform. In simplest terms, it is a report builder — and a very good one. It is designed to make reporting accessible to business users, not just technical experts.

Many of our customers use Power BI to extract, analyze, and report data from the system. Here is a quick guide to help you get started.

## Overview

The API uses [Bearer authentication](https://swagger.io/docs/specification/v3_0/authentication/bearer-authentication/) to secure access to the data in your account.

This means you'll use Bearer token authentication to prove that Power BI has permission to access your data, whenever you connect Power BI to the API as a data source.

**What is a bearer access token?** A bearer access token is like a digital key that the API provides to authorize access to your data. Think of your access token as a temporary pass that says "whoever has this token is allowed to read my data."

**How it works with Power BI:**

1. You sign in as a CMDS developer, integrator, or administrator, and generate your own private access token.
2. When you configure a data connection in Power BI, you'll enter this token in the authentication settings.
3. Power BI will then use your token to identify itself to the API each time it needs to refresh your data.

## Step 1: Make sure your developer account is enabled

If you are working with the API for the first time, then always start in the Development environment.

Sign in and visit the My Profile page. If your account is enabled for development and integration work with the API then you'll see a Developer Settings panel on this page.

![Developer Settings panel on the My Profile page](../../assets/developers/power-bi-1.png)

If you don't see a Developer Settings panel then contact your LMS administrator to have this enabled for your account.

## Step 2: Generate an access token from your client secret

Visit the My Profile page and click the key beside the API Access Token label in the Developer Settings section. The system will create a token that you can copy to your clipboard with a single mouse-click.

![Generating an API access token](../../assets/developers/power-bi-2.png)

## Step 3: Create a data source in Power BI

Start the Power BI Desktop app on your computer and create a new report.

When you are prompted for a data source, select "Get data from another source". In the "Get Data" dialog box, select "Web".

![Selecting Web as the data source type in Power BI](../../assets/developers/power-bi-3.png)

In the "From Web" dialog box, select "Advanced" and input the settings for the URL parts and the HTTP request header.

#### URL parts

You can input the entire, fully-qualified URL for an API endpoint as a single URL part (in one of the available text boxes), or you can separate the URL into logical pieces so it is easier to read and understand. Our team prefers the latter, but of course this is optional. In the example below, you'll see:

- In the first part I identify the base URL for the server where the API is hosted. This is copied directly from the Developer Settings panel of my profile.
- In the second part I identify the specific request that I want to send.
- In the third part I specify additional options and/or input parameters for my query.

#### HTTP request header

- The parameter name is "Authorization".
- The parameter value is the word "Bearer", followed by a blank space, followed by my access token.

Here is an example for reference:

![From Web dialog box with URL parts and Authorization header](../../assets/developers/power-bi-4.png)

## That's it!

Click "OK", and the data source is ready to use in Power BI.

![Power BI data source ready to use](../../assets/developers/power-bi-5.png)

## Next steps: explore and experiment

Spend some time exploring the API libraries, and experiment with your Power BI integration. The development environment is intended for this purpose, so you can test and debug your Power BI reports without any impact on your organization's live, production environment.

!!! success
    There are more than twenty API libraries available in the platform, with hundreds of available queries.

### Need technical help?

Of course, if you get stuck, we have a professional services team with deep knowledge of the platform, and many years of experience building integrations between systems — including large-scale data migrations. Our team is always excited about working with other developers and integrators who are building their own integrations, migrations, and extensions.

!!! info
    You can leverage our team through a simple consulting services agreement, which can be short-term or long-term. If you're just getting started, then we usually recommend a part-time resource (half-time or quarter-time) for a period between one and six months.

We can also recommend third-party integration partners, if you'd prefer to work with someone who has an orientation and perspective on the platform that is more externally focused.

Contact us any time to discuss either of these options.
