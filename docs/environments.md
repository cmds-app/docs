# Environments

CMDS runs in three separate environments - **Test**, **Demo**, and **Live** - each serving a different purpose. Understanding what each one is for will help you know which one to log in to and what you can expect when you do.

## Why three environments?

Running CMDS as a single "one size fits all" system would be risky. New features could affect real learners mid-course; a developer testing a change could accidentally touch live records; there'd be nowhere safe to practice before rolling something out.

Separating the three jobs - building, previewing, and running - gives each its own space:

- Developers can build and break things without consequence.
- You can preview new features and practise workflows before they affect your people.
- Your real learners work in a stable environment with their real data.

All three environments run the same software. What differs is the audience, the data, and how stable things are.

## Test

**For the development team and for integrators.** This is the workspace where our developers build and validate new features. Code changes appear here first, often several times a day. Data resets frequently and nothing here is considered permanent.

If you are building an integration against the CMDS API, build and test it here, against `https://test-api.cmds.app`, before you point it at Live. Otherwise you generally won't be invited to Test unless you're actively working with our team on a feature or debugging something. It's noisy and experimental, and not meant for everyday customer work.

## Demo

**For you to preview and practise.** Demo is where each release lands about a week before it goes Live. If you want to see a new feature before your learners do, or rehearse a training program, or explore a configuration change safely, Demo is the place.

Demo uses a separate dataset from Live. Nothing you do here affects your real users, and nothing they do affects you. It's a safe place to poke around, make mistakes, and learn.

To log in to Demo, choose your organization on the [Demo links](https://www.keyeracmds.com/demo-links/) page.

**Tip:** check [What's new in CMDS](changelog/index.md) to see when each release will appear in Demo.

## Live

**For your real users.** Live is the production environment your learners, validators, and administrators use every day. It holds your real data - completions, certificates, registrations - and it's the environment your reports and integrations pull from.

Live is the most stable environment. Updates only arrive after a release has spent a week in Demo, giving our team and yours time to catch anything that needs attention before real users see it.

To log in to Live, choose your organization on the [Partners](https://www.keyeracmds.com/partners/) page.

## Quick comparison

| Environment | Audience                        | Data        | Stability |
| :---------- | :------------------------------ | :---------- | :-------- |
| Test        | Development team, integrators   | Throwaway   | Low       |
| Demo        | You, for previewing & practice  | Separate    | Medium    |
| Live        | Your real learners              | Real data   | High      |

## Which one do I log in to?

- Doing your normal work? Use [**Live**](https://www.keyeracmds.com/partners/).
- Want to try a new feature, practise a workflow, or test a setting? Use [**Demo**](https://www.keyeracmds.com/demo-links/).
- Building an integration against the API? Use **Test** (`https://test-api.cmds.app`), then move to Live.
- Working with our development team on a specific issue? Use **Test** (we'll point you there).

If you're unsure, start with **Live**.
