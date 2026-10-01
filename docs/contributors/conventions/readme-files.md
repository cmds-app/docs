# README files

A README is a short summary of the contents of a directory. It provides critical information for people browsing your code, especially first-time users.

The contents of the file are displayed in GitHub when you view the contents of the containing directory. For example, the README.md file is rendered when you view the contents of the containing directory:

- [Style guides for Google open-source projects](https://github.com/google/styleguide/tree/gh-pages)

## Readable README files

README files must be named `README.md`.

The file name must be uppercase `README`, and the file extension must be lowercase `md`.

This causes it to stand out - because lowercase and Title Case filenames are much more common. Also, on [Unix-like](https://en.wikipedia.org/wiki/Unix-like) systems, the [`ls`](https://en.wikipedia.org/wiki/Ls) command sorts and displays files in [ASCII-code order](https://en.wikipedia.org/wiki/ASCIIbetical), so uppercase filenames appear first.

## Where to put your README

Every repository has a `README.md` at its root. Inside a repository, a folder gets its own `README.md` when people browse it to find their way, such as `tests/manual/notices/`, where the README holds the procedure every script in the folder follows. A source project under `src/` does not need one: the repository README and the code reference site describe the projects.

## What to put in your README

At a minimum, your `README.md` file should contain a link to user- and/or team-facing documentation.

The repository `README.md` should include (or link to) the following information:

1. A summary of the purpose and contents of the package or library.
2. A list of relevant contacts.
3. The status of the package or library. For example, is it deprecated, not for general release, etc.
4. A description of how to use the package or library.
5. Links to additional relevant documentation.
