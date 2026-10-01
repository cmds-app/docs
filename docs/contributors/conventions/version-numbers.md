# Version numbers

Every build gets a version number that no other build has, wherever the build runs. You'd expect a timestamp to be the simplest way to guarantee that, but two builds in the same minute collide, and a timestamp says nothing about what changed. Instead, the release build asks a central version service for the next number, and the service hands out each number exactly once.

## Major.Minor.Patch

Version numbers follow [Semantic Versioning](https://semver.org/). For example:

- **5.0.33**

| Part | Example | Meaning |
| :--- | :------ | :------ |
| Major | `5` | The generation of the platform. `5` is CMDS version 5. This changes only when the platform itself is replaced. |
| Minor | `0` | Raised for a build that adds a significant new capability. The patch number resets to `0`. |
| Patch | `33` | Raised for every other build. This is the default. |

## How a build gets its number

The release build script in `build/` starts by asking the version service for a bump. It sends the level (`major`, `minor`, or `patch`) and gets back the new version number. The level defaults to `patch`, so an everyday build needs no argument, and a minor or major bump is always a deliberate choice:

```powershell
.\build\build.ps1 -BumpLevel minor
```

Because the service keeps the counter, a build on a developer's machine and a build on a CI runner can never be given the same number, and a failed build simply leaves a gap in the sequence.

## One number for the whole release

Every package in a release carries the same number: the API, the command-line tool, the web app, and the operations scripts.

- **.NET assemblies.** The number is stamped into the .NET assemblies at compile time.
- **Web bundle.** It is stamped into the web bundle, so the web app can show which build it is.
- **Package files.** It is part of every package file name, for example `<Package>.5.0.33.zip`.
- **Deployment.** The release in the deployment tool is created with the same number.

To check which build an environment is running, ask the API:

```
GET diagnostic/version
```

## Release names in the changelog

The [changelog](../../changelog/index.md) names scheduled releases with the two-digit year and a release number within that year, such as 26.5. A release name marks a date on the release calendar, and one scheduled release can include many builds, each with its own version number.
