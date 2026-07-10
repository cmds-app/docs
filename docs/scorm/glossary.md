# SCORM glossary

Essential terms for HR managers, training directors, safety coordinators, and instructional designers who work with eLearning content using the Sharable Content Object Reference Model (SCORM).

## A

**Activity**: Think of this as any piece of your training course - whether it's a single lesson, a quiz, or an entire module. In SCORM 2004, every component of your course is considered an "activity." Some activities are actual training content (like a video lesson), while others are simply containers that organize multiple activities together.

**Activity Tree**: The complete structure of your SCORM course, showing how all the activities relate to each other - like a family tree for your training content. This helps the LMS understand the flow and organization of your course.

**ADL (Advanced Distributed Learning)**: The U.S. Department of Defense research group that created and maintains SCORM standards. Think of them as the governing body that ensures SCORM remains consistent and up-to-date across the industry.

**Aggregation**: A container that holds multiple pieces of training content together. Like a folder that contains several related documents, an aggregation groups related activities in your course.

**AICC (Aviation Industry CBT Committee)**: An older eLearning standard that came before SCORM. While originally designed for aviation training, AICC was widely used across industries and helped lay the groundwork for SCORM development.

**API (Application Programming Interface)**: The "translator" that allows your training content to communicate with your LMS. When a learner completes a lesson or takes a quiz, the API ensures that information gets properly recorded in your LMS.

**Asset**: A piece of training content that doesn't need to communicate with your LMS - like a PDF document, image, or video file. Assets are the building blocks that make up your more interactive training components.

**Attempt**: A single try at a course or quiz, from launch to exit. Depending on how the course and LMS are configured, relaunching may resume the same attempt or start a new one - which matters when you report on quiz retakes.

**Authoring Tool**: Software used to build SCORM courses - like Articulate Storyline, Adobe Captivate, or iSpring. These tools handle SCORM's technical packaging automatically, so course designers can focus on content.

## B

**Bookmarking**: The everyday term for a course remembering where a learner left off, so they can resume without starting over. See Suspend Data for how this works under the hood.

## C

**Choice Navigation**: Allows learners to jump around your course by choosing from a menu or table of contents, rather than following a fixed sequence. Perfect for experienced learners who want to skip to specific topics.

**Completion Status**: Whether a learner finished the course - completed or incomplete. Note this is separate from whether they passed: a learner can view every screen and still fail the quiz. See Success Status.

**Content Package**: Your complete SCORM course bundled together in a format that any SCORM-compliant LMS can understand and deliver. It's like having all your training materials in a standardized container that works everywhere.

**Cross Domain**: A technical term for when your training content is hosted on a different web server than your LMS. This can sometimes cause communication issues, but modern systems usually handle this automatically.

## D

**Data Model**: The standardized set of information that your training content can share with your LMS - things like completion status, quiz scores, time spent, and progress tracking. This ensures consistent reporting regardless of which authoring tool created your content.

**de facto**: A standard that's widely adopted by choice rather than by law. SCORM became the de facto standard for eLearning because it solves real business problems, not because anyone was forced to use it.

**Dependency**: When one piece of your training content relies on another piece to work properly - like a quiz that needs access to images or videos from elsewhere in the course.

**Descriptor Files**: The "instruction manual" that tells your LMS everything it needs to know about your training content - what it contains, how it's organized, and how to launch it. In SCORM, this is always a file called `imsmanifest.xml`.

**DoD (Department of Defense)**: The U.S. government agency that sponsors ADL and originally drove the creation of SCORM to standardize military training systems.

## E

**ECMAScript**: The official standard that JavaScript is based on - the programming language used in SCORM communication. You don't need to know JavaScript to use SCORM, but this term might come up in technical discussions.

**Environment**: A separate copy of a system, each serving a different stage of the software lifecycle. Like Runbook, this is a general IT term rather than a SCORM one, but it comes up whenever we discuss where to try something out. The typical lifecycle environments are:

- **Test** - testing environment for automated tests (unit and integration), manual quality assurance testing by internal teams, and user acceptance testing by external teams for customer signoff. Also called: dev, qa, uat.
- **Demo** - pre-release environment with near-parity to production, used to preview upcoming releases and for product demos and training. Also called: sandbox, staging.
- **Live** - production environment with real users and real data. Also called: prod, production.

See [Environments](../environments.md) for what each CMDS environment is for and which one to log in to.

## F

**Flow Navigation**: Simple "Next" and "Previous" buttons that let learners move through your course in sequence. The most common and straightforward way for learners to navigate training content.

## H

**HACP (HTTP AICC Communication Protocol)**: A communication method used by the older AICC standard. While mostly replaced by SCORM, you might encounter this term when dealing with legacy content or systems.

## I

**IEEE LTSC (IEEE Learning Technology Standards Committee)**: A formal standards organization that has officially recognized and accredited several parts of SCORM, giving it additional credibility and stability.

**IMS Global Learning Consortium**: An organization that develops educational technology standards, several of which are incorporated into SCORM.

**Interaction**: An individual learner response recorded by your course - typically a single quiz question and its answer. Courses that report interactions let you see per-question detail in your reports, not just the final score.

**Item**: Individual components of your training course as they appear in the course structure - each lesson, module, or assessment is represented as an "item" in the SCORM manifest.

## L

**LETSI (International Federation for Learning, Education, and Training Systems Interoperability)**: An organization that took over some SCORM stewardship responsibilities from ADL, working to advance eLearning standards.

**LMS (Learning Management System)**: Your platform for delivering, tracking, and managing online training - systems like CMDS, Moodle, and Blackboard.

**LRS (Learning Record Store)**: A newer concept that works with advanced tracking standards like xAPI (Tin Can API). Think of it as a more sophisticated database for storing detailed learning analytics and experiences.

## M

**Manifest**: The master file (always named `imsmanifest.xml`) that describes your entire SCORM course to the LMS - its contents, structure, and delivery requirements.

**Metadata**: Descriptive information about your training course - title, description, learning objectives, technical requirements, and keywords. This helps with course discovery and management in your LMS.

## O

**Organization**: A specific way of arranging and presenting your training content. One course can have multiple organizations - for example, one version for beginners and another for advanced learners.

## P

**Package**: Simply another term for a complete SCORM course, emphasizing that it comes as a self-contained unit ready for delivery.

**PENS (Package Exchange Notification Services)**: A standard that enables one-click publishing from authoring tools directly to your LMS, streamlining the content deployment process.

**PIF (Package Interchange File)**: Your SCORM course compressed into a ZIP file for easy transfer and upload to your LMS.

**Prerequisites**: SCORM 1.2's simple way to control course order - requiring one item to be finished before another unlocks. SCORM 2004 replaced this with the more powerful Sequencing rules.

## R

**Resource**: The actual training materials in your course - the lessons, assessments, videos, and documents that learners interact with. Resources are the "meat" of your training content.

**RTWS (Run-time Web Services)**: An advanced standard that extends SCORM capabilities to mobile devices, games, and simulations, allowing eLearning to work beyond traditional web browsers.

**Runbook**: A step-by-step guide for carrying out a routine administrative procedure - for example, onboarding a new group of workers or preparing training assignments before an audit. Runbooks aren't part of the SCORM standard; the term comes from IT operations, but you may hear it when working with our team on repeatable admin processes.

## S

**Schema Definition Files**: Technical files that define the exact format and rules for SCORM manifests. Your authoring tool handles these automatically, but they ensure your content package follows SCORM standards precisely.

**SCO (Sharable Content Object)**: The core building blocks of SCORM courses - individual training components that can communicate with your LMS and be reused across different courses. SCOs are what make your training content truly "sharable" and trackable.

**SCO Library**: In CMDS, the collection of SCORM packages uploaded for your organization on your SCORM hosting platform. You add a package to your SCO library once, then reference it from any learning activity.

**SCORM (Sharable Content Object Reference Model)**: The standard itself - a set of technical rules that lets online courses and learning management systems work together, no matter who built them. If a course is SCORM-compliant, it will run in any SCORM-compliant LMS, including CMDS.

**SCORM 1.2**: The most widely used version of SCORM, released in 2001. Simple, stable, and supported almost everywhere. See [versions](versions.md) for how it compares to SCORM 2004 and xAPI.

**SCORM 2004**: The later version of SCORM, released in stages ("editions") from 2004 onward. It adds sequencing, separate completion and success tracking, and more detailed reporting. See [versions](versions.md) for a comparison.

**Sequencing**: The rules that control the order learners move through your course - for example, requiring a safety video to be watched before the quiz unlocks. Sequencing is defined in SCORM 2004; SCORM 1.2 leaves ordering up to the course itself.

**Success Status**: Whether a learner passed or failed, based on the course's scoring rules. Separate from Completion Status - SCORM 2004 tracks the two independently, while SCORM 1.2 combines them into a single status field.

**Suspend Data**: The information your course saves when a learner exits partway through - their current place, answers so far, and anything else needed to resume later right where they left off.

## T

**Tin Can API**: The original nickname for xAPI, coined while the standard was in development. You'll still see this name in older tools and documentation - it refers to the same standard. See xAPI.

## X

**xAPI (Experience API)**: A newer standard that goes beyond SCORM by tracking learning experiences wherever they happen - mobile apps, simulations, even offline activities. Results are recorded as simple statements ("learner completed safety course") and stored in an LRS. CMDS supports launching xAPI (Tin Can) content alongside SCORM.
