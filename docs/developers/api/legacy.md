# Legacy (API v1)

Version 1 of the API provides a basic toolset for building integrations and reporting solutions. It includes tools for reporting on learners, departments, achievements, competencies, and job profiles — as well as updating and importing contacts, and managing event registrations.

!!! info
    Contact our service and support team to have your developer account enabled.

The CMDS Developer Application Programming Interface (API) allows you to access the data in your account through a secure programming interface. It is a [RESTful API](https://restfulapi.net) based on [HTTPS](https://datatracker.ietf.org/doc/html/rfc2818) requests and [JSON](https://www.json.org/json-en.html) responses, which means you can use your programming language of choice.

## Getting started

The easiest way to begin using the API is to click **Explore** at the top of the API Reference page listing all the available API methods. We use [Swagger](https://swagger.io/) as our API documentation platform.

[API Reference](https://dev-demo.cmds.app/swagger)

We use [Insomnia](https://insomnia.rest) to design, debug, and test all our APIs. [Postman](https://www.postman.com) is another excellent tool we recommend to developers looking for a tool to test and debug their API requests.

## Endpoints

CMDS is a multitenant system. This means the endpoint URL must identify your _environment_ and your _organization_.

**For example**, if your organization account is **acme** then the base address for all endpoint URLs is this:

- Development: `dev-acme.cmds.app/api`
- Sandbox: `sandbox-acme.cmds.app/api`
- Production: `acme.cmds.app/api`

Please remember all requests must be secured using HTTPS (port 443).

## Need help?

Please send email to the CMDS service and support team if you have any questions: [support@cmds.app](mailto:support@cmds.app)

## Authorization

The API uses the OAuth Bearer Token authorization scheme.

A bearer token (also known as an [access token](https://www.oauth.com/oauth2-servers/access-tokens/)) is a cryptographically strong sequence of random values. It serves to identify and authenticate your access to the system, and it determines the permissions available to you.

Your application must send this token in the Authorization header when making requests to protected resources.

Developer access tokens are available upon request.

## Throttling

The API includes a built-in dynamic throttling mechanism to prevent a single developer from abusing the system and causing adverse effects for others. It works by having a rate limit, and an estimated computation cost per request. Each request subtracts from your quota, and the quota is automatically replenished over time.

In the event that your API request is throttled, you will receive a 403 Forbidden (Rate Limit Exceeded) response. Your application should be prepared for this error, and retry the request at a later time.

## Scheduled maintenance windows

Please note a Maintenance Window is scheduled every Wednesday evening between 20:00 – 21:00 Mountain Time. The API may be unavailable for a short period during this interval of time.

If the API is able to respond normally to an incoming request during a Maintenance Window, then it does so.

If the API is unable to respond normally, because a maintenance operation is executing on the database, then the API indicates this with a response instructing the caller to wait and retry. External systems should be prepared for this case, and retry their request at a later time.
