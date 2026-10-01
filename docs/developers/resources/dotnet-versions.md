# .NET

A few important details about the Microsoft .NET platform.

## Versions

We use each of these versions of .NET for specific purposes:

- [.NET Framework 4.8](https://versionsof.net/framework/4.8/)
- [.NET Standard 2.0](https://learn.microsoft.com/en-us/dotnet/standard/net-standard?tabs=net-standard-2-0)
- [.NET 10](https://versionsof.net/core/10.0/) (from version 26.5; earlier versions targeted .NET 9)

### Dependencies

.NET Framework and .NET Core dependencies can be summarized this way:

- You **can** reference a .NET Standard assembly from .NET Framework and from .NET Core.
- You **cannot** reference a .NET Core assembly from .NET Framework.
- You **can** reference a .NET Framework assembly from .NET Core.

!!! note
    .NET Framework does **not** support .NET Standard **2.1** and our .NET Framework assemblies need to reference .NET Standard assemblies. Therefore, we target .NET Standard **2.0** in a library that needs to be used by both .NET Framework and .NET Core.

## Development tools

- VS Code with the C# Dev Kit extension is the recommended editor for all development work: .NET, React, and the documentation. See [VS Code](../../contributors/tools/vscode.md) for the extensions.
- The exception is the CMDS V4 codebase, which targets .NET Framework 4.8 and builds ASP.NET Web Forms projects. The C# Dev Kit does not build those, so V4 work needs Visual Studio.
