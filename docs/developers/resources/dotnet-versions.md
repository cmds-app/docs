# .NET

A few important details about the Microsoft .NET platform.

## Versions

We use each of these versions of .NET for specific purposes:

- [.NET Framework 4.8](https://versionsof.net/framework/4.8.1/)
- [.NET Standard 2.0](https://learn.microsoft.com/en-us/dotnet/standard/net-standard?tabs=net-standard-2-0)
- [.NET Core 9.0](https://versionsof.net/core/9.0/)

### Dependencies

.NET Framework and .NET Core dependencies can be summarized this way:

- You **can** reference a .NET Standard assembly from .NET Framework and from .NET Core.
- You **cannot** reference a .NET Core assembly from .NET Framework.
- You **can** reference a .NET Framework assembly from .NET Core.

!!! note
    .NET Framework does **not** support .NET Standard **2.1** and our .NET Framework assemblies need to reference .NET Standard assemblies. Therefore, we target .NET Standard **2.0** in a library that needs to be used by both .NET Framework and .NET Core.

## Development tools

- Visual Studio 2022 is the recommended IDE for all .NET Framework development work.
- VS Code is the recommended IDE for all React development work.
- Either (or both) tools can be used for .NET Standard and .NET Core development work.
