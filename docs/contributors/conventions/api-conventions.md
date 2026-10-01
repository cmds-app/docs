# API conventions

The API is an ASP.NET Core app with MVC controllers, and a controller does very little: it reads the request, asks a repository for data, and shapes the response. The SQL lives in the repository, where you can read it in one place.

Here is a typical endpoint, lightly trimmed from the real code (the product namespace is illustrative):

```csharp
namespace Product.Api.Certification.Plans;

public sealed class AssignmentsController : ControllerBase
{
    private readonly PlanRepository _plans;

    private readonly PrincipalAccessor _principals;

    public AssignmentsController(PlanRepository plans, PrincipalAccessor principals)
    {
        _plans = plans;
        _principals = principals;
    }

    /// <summary>Assignments, one page at a time.</summary>
    [HttpGet("certification/assignments")]
    [ProducesResponseType(typeof(JObject), StatusCodes.Status200OK)]
    public async Task<ActionResult<JObject>> AssignmentsAsync(
        [FromQuery] AssignmentQuery query,
        CancellationToken cancellation)
    {
        var scope = _principals.Require().ResolveRequestCompany(query.CompanyId);

        var (rows, total) = await _plans.SearchAssignmentsAsync(scope, query, cancellation);

        return Ok(new
        {
            items = Projection.Apply(rows, query.Filter.Includes),
            total,
            page = query.ClampedPage,
            pageSize = query.ClampedPageSize,
        });
    }
}
```

## Routes

- **Full route on each action.** Every action carries its complete route in its HTTP attribute (`[HttpGet("certification/assignments")]`). There is no class-level `[Route]`, so you can read the URL of an endpoint without looking anywhere else.
- **No `/api` prefix.** The API never names its own mount point. Deployed, it is the root of its own host (`test-api.cmds.app`, `api.cmds.app`), so a request arrives at a controller as `/certification/plans`. Only in development does the SPA address it as `/api` through the Vite proxy, and `UsePathBase` strips that prefix there. Moving the API to another host or path is a configuration change, not a code change.
- **Lowercase, grouped by area.** A route starts with its feature area and uses plural nouns for collections: `certification/plans`, `notification/dispatches/{dispatchId:guid}/approve`. Multi-word segments are kebab case (`me/client-secret`).
- **Typed route parameters.** A route parameter is camel case and carries a type constraint (`{dispatchId:guid}`), so a malformed id is a `404` before any code runs.

## Responses

- **JSON is camel case.** Property names are camel-cased on the way out, whatever the C# name.
- **Collections are paged.** A collection returns `{ items, total, page, pageSize }`. The page size defaults to 25 and is capped at 200. An out-of-range page is corrected rather than rejected, so a caller asking for page 0 gets the first page, not a `400`.
- **Errors are problem details.** An error is an [RFC 7807](https://www.rfc-editor.org/rfc/rfc7807) response built with `Problem(...)`, with a short `title` and a `detail` that tells the caller what to do next:

```csharp
return Problem(
    title: "Step locked.",
    statusCode: StatusCodes.Status409Conflict,
    detail: "Complete the prerequisite step before this one.");
```

A missing resource can return a bare `NotFound()`. Unhandled exceptions go through the exception handler, which also writes a problem response.

## Repositories

A repository is a `sealed` class per feature area (`PlanRepository`, `DirectoryRepository`), registered for dependency injection and given the database through its constructor. It uses Dapper with hand-written SQL:

- Queries are raw string literals, so the SQL reads the way you would type it into `psql`.
- Every value is a parameter (`@CompanyId`), never concatenated into the SQL.
- Columns are aliased to the C# property names (`company_name AS Name`), so Dapper maps rows with no configuration.
- Calls go through `CommandDefinition` with the request's `CancellationToken`, so a client that disconnects cancels its query.

There is no ORM, and no generic repository. If an endpoint needs a new query, write the query.

## Cross-cutting concerns

Some rules apply to every request, so they live in the request pipeline rather than on each action:

- **Authentication.** A gate in the pipeline checks every request before it reaches a controller. Actions do not carry `[Authorize]` attributes.
- **Company scope.** The request names the company it acts for, and `PrincipalAccessor` resolves it against what the caller is allowed to see. A repository applies that scope in its `WHERE` clause, so data from another company never leaves the database.
- **Rate limiting.** A global limiter runs before the authentication gate and answers `429` with a `Retry-After` header.
