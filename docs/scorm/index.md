# Overview of SCORM in CMDS

Welcome! If you deliver online training through CMDS, SCORM is probably part of your world, and the good news is that **CMDS fully supports both hosting and delivery of SCORM-packaged training content**. You can drop a SCORM course straight into a learning activity, and CMDS handles the rest: launching it for your learners, tracking their progress, and feeding completions back into your records.

This section walks you through it all:

- **New to SCORM?** Start with the short [What is SCORM?](#what-is-scorm) below for a plain-language overview.
- **Need a definition?** The [glossary](glossary.md) explains the terms you'll come across.
- **Wondering which version to use?** See [versions](versions.md) for a quick comparison of SCORM 1.2, SCORM 2004, xAPI, and friends.
- **Ready to add a course?** Follow the step-by-step walkthrough in [tutorials](tutorials.md).

## What is SCORM?

SCORM is a standard that lets online courses work the same way across different learning systems. Think of it as a common language: a course built with any popular authoring tool (like Articulate or Captivate) will run correctly in CMDS, and in any other SCORM-compatible system.

A SCORM course is just a ZIP file that packages everything the course needs: videos, quizzes, images, and the rules for how learners move through them. Because it's a standard package, you can build a course once and use it in multiple systems without having to rebuild it.

SCORM also tracks what your learners do. Completion status, quiz scores, and time spent are all reported back automatically, so you can run accurate reports without any extra work on your part.

## How SCORM works in CMDS

CMDS fully supports SCORM. When you add a SCORM course to a learning activity, learners can launch and complete it like any other CMDS content, and their progress flows back into your records.

You'll store the actual SCORM course files (the ZIPs) on a **SCORM hosting platform**, and CMDS will launch them for learners from there.

### OpenSCORM

CMDS hosts SCORM content on [OpenSCORM](https://www.openscorm.com) (nicknamed Scoop). It's inexpensive and easy to use, and its web front end is open source. CMDS connects to it behind the scenes, so learners launch a course without a second sign-in, and adding a SCORM course to a learning activity takes just a few clicks.

CMDS also supports SCORM courses on OpenSCORM that are packaged in more than one language.

!!! note
    From version 26.5, OpenSCORM is the only SCORM hosting platform CMDS supports. Earlier versions could also launch courses from SCORM Cloud; that integration has been retired.

## Need help?

If you need a hand setting up a SCORM course, reach out to our support team. We're happy to help.
