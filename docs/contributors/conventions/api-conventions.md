# API conventions

A projection (query) table stores the current-state for an aggregate change (event) stream. This is the reason there are no API methods available to create, modify, or delete entities stored in these tables in the same way this is done for base relational tables. Instead, changes to the state of an aggregate can be done **only** using commands.

```csharp
// HTTP method and route
[HttpHead("$CollectionPath/$CollectionKey")]

// Authorization and filters
[HybridAuthorize($EntityPolicy.Assert)]

// OpenAPI metadata
[ProducesResponseType<bool>(StatusCodes.Status200OK)]
[EndpointName("assert$EntityName")]

public async Task<ActionResult<bool>> AssertAsync(
    $PrimaryKeyMethodParameters,
    CancellationToken cancellation = default)
{
    var exists = await _$EntityNameVariableService.AssertAsync($PrimaryKeyMethodArguments, cancellation);
    return exists ? Ok() : NotFound();
}
```
