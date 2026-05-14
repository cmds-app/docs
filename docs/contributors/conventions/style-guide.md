# Style guide

Conventions for a consistent, unified approach to layout and style throughout the user interface.

## Overview

As a general rule, we follow the principles and practices in Google's Material Design style guide. Any time you are uncertain about how to proceed with a style decision, please refer to it for guidance.

The official reference is here: [Material Design style guide](https://m3.material.io/foundations/content-design/style-guide/ux-writing-best-practices).

## Tabs

The sequence of the tabs on a form should follow this basic rule:

Primary/essential content → Secondary content → Advanced/optional content

Tabs should represent a logical information architecture, and should use progressive disclosure (don't overwhelm with too much detail on the first tab).

For example:

- Basic Info (required, foundational)
- Advanced Settings (optional, builds on basic)
- Permissions (contextual, depends on other settings)
- Review (summary, final step)

## Buttons

### Placement

Button placement depends on the specific context and type of action. **Bottom placement** is preferred for:

- **Form submission buttons** (Save, Submit, Continue) — users expect these at the bottom after completing the form
- **Wizard/stepper navigation** (Next, Previous, Finish)
- **Modal dialogs** — actions typically appear at the bottom
- **Mobile interfaces** — bottom placement is more thumb-friendly

**Top placement** is preferred for:

- **Page-level actions** (Create New, Add Item, Export)
- **Toolbar actions** (Edit, Delete, Share) that apply to the entire page or selected content
- **Navigation actions** that don't require form completion
- **Destructive actions** that you want to separate from form submission buttons

Material Design principles specify:

- **Forms**: Primary actions should be at the bottom, following the natural completion flow
- **Content pages**: Actions can be at the top in app bars or floating action buttons
- **Mobile**: Consider reachability — bottom placement is often more accessible

### Alignment and sequence

On web forms, buttons should be placed at the bottom of the page, aligned to the left margin. The correct sequence (from left to right) is:

1. **Save** (primary action — leftmost)
2. **Cancel** (dismissive action — next to primary)
3. **Duplicate** (secondary action)
4. **View References** (secondary action)
5. **Delete** (destructive action — rightmost or separated)

The key principle here is:

- **Primary actions go first** (leftmost) in the natural reading flow
- **Dismissive actions** (e.g., Cancel) typically appear next to the primary action
- **Destructive actions** (e.g., Delete) are placed last or visually separated

This follows the logic that users read left-to-right and encounter the most important action first. The "Save then Cancel" pairing at the beginning creates a clear primary action hierarchy.

When it is possible to do so, buttons that perform destructive actions should be separated entirely. For example, a Delete button should be placed in a different area of the form, rather than mixing it with form submission buttons.

## Confirmations

The prompt for confirmation of a destructive action should look like this:

![Confirmation prompt for a destructive action](../../assets/conventions/confirmation-prompt.png)

## Tooltips

Tooltips provide brief, contextual help for UI elements. They should be concise, scannable, and easy to understand.

**Tone:**

- Use a clear, neutral, and instructional tone.
- Avoid jargon, unless it is widely understood by users.

**Length:**

- Aim for one sentence or less.
- Avoid multiple sentences or blocks of text.

**Punctuation:**

- **Do not use ending punctuation** (like periods) **for short phrases or fragments**.
  _Example: "Displays on the learner's dashboard"_
- **Use a period** if the tooltip is a complete sentence.
  _Example: "This text appears under the achievement title."_

**Grammar:**

- Use sentence case (capitalize the first word).
- Use active voice when possible.

**Icons:**

- Including an icon is optional.
- When you include an icon in a tooltip, follow a consistent semantic hierarchy:
    - Question mark for help/documentation
    - Info for basic information
    - Lightbulb for insights and quick tips

**Examples:**

- Bad: "this text will be shown under the achievement title."
- Good: "This text appears under the achievement title."
- Good: "Appears under the achievement title"

## Grids

Action icons in data tables and grids should be placed in the **right-most column**.

This follows the natural reading flow (left-to-right in most languages) where users first scan the data content and then encounter the actions they can take on that data. There are some exceptions:

- **Selection controls** (like checkboxes) are typically placed in the left-most column
- In some cases, a single primary action icon might be placed on the left if it is the most important element for that row

The right-aligned approach for action icons is part of Material Design's broader principle of creating a clear visual hierarchy and intuitive user flow in a data-dense interface element.
