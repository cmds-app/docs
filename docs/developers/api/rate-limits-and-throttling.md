# Rate limits and throttling

## Dynamic throttling system

The system incorporates a dynamic throttling mechanism designed to maintain fair resource allocation and prevent any single developer from monopolizing system resources in ways that could degrade performance for others.

## How it works

The throttling system operates on a token bucket model with two core components:

- **Rate Limit**: A maximum quota of requests allocated to each developer
- **Request Cost**: Each API request consumes a portion of your quota based on its resource intensity

When you make a request, the associated cost is deducted from your available quota. Your quota automatically replenishes at a steady rate over time, ensuring continuous access while preventing burst abuse patterns.

## Handling throttled requests

If your request is throttled due to insufficient remaining quota, the API will return a `403 Forbidden` response with the status message "Rate Limit Exceeded." Your application should implement robust error handling to gracefully manage this scenario by:

- Catching the 403 response code
- Implementing exponential backoff or scheduled retry logic
- Deferring the request until quota has been replenished

## Monitoring your usage

To help you proactively manage your API consumption and avoid throttling, every response includes informative headers:

- **`X-Request-Cost`**: A floating-point value indicating the exact quota amount consumed by the current request
- **`X-Rate-Limit-Remaining`**: Your current remaining quota balance (only included when throttling is active for your account)

By monitoring these headers, you can build intelligent rate-limiting logic into your application and optimize request patterns to stay within your allocated quota.
