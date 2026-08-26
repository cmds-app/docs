# Insomnia

The API client the team uses to design, debug, and test the CMDS API. It is also a good way to explore the endpoints before writing integration code.

## Getting started

- Import the API's OpenAPI (Swagger) description to load every endpoint at once.
- Set the base URL for the environment you are working against - `https://api.cmds.app` for production, `https://test-api.cmds.app` for the sandbox.
- Authenticate with a personal API secret, sent as a bearer token in the `Authorization` header. See [Authentication](../../developers/api/authentication.md).
