# Component Architecture

This file is loaded as instructions when working in `lib/components/`.
It codifies the component architecture from `/DESIGN.md` as a procedure
to follow.

## Component inventory

| File | Role | Purpose |
|---|---|---|
| `nav.dart` | chrome | Site-wide top navigation bar with monogram, links, theme toggle |
| `footer.dart` | chrome | Site-wide footer with year, social links, admin-lock icon |
| `hero.dart` | section | Home-page hero: name, lede, portrait, sq-marks, social row |
| `research_grid.dart` | section | Home-page grid of research paper cards |
| `writing_list.dart` | section | Recent-blog-posts list (home and /writing) |
| `social_icons.dart` | atom | Row of small social-platform icon links from site.yaml |
| `theme_toggle.dart` | atom (side-effecting) | Dark/light toggle — switches document data-theme via inline JS, no Dart hydration |
| `admin/admin_shell.dart` | layout | Auth gate + rail mount + page body slot for /admin/* pages |
| `admin/rail.dart` | chrome | Vertical navigation rail for admin: profile/blog/research + logout |
| `admin/topbar.dart` | chrome | Admin header bar: section name + save state + action button |

## Roles

- **chrome** — persistent UI surrounding page content (nav, footer, rail, topbar)
- **section** — self-contained content area on a page (hero, grid, list)
- **atom** — small reusable primitive used inside sections or chrome (icon, toggle)
- **layout** — pure layout/wrapper with no content of its own (shell)

## The dependency rule

Higher-complexity components depend on lower-complexity ones, never the
reverse. Atom works in isolation. Section can use atoms. Chrome can use
atoms and sections. Layout wraps chrome and sections. Pages compose
everything. A component must not import a page.

## Decision tree: before creating or modifying a component

Work through these **in order**. Stop at the first "yes."

1. **Does an existing component already do this?** → USE IT. Stop.
2. **Does an existing component do almost this?** → EXTEND IT, but only
   with CSS-only variants. Apply this rule:

   **Extend (don't create new) when the change is:**
   - A class modifier that swaps a custom property or colour (e.g.
     `pill--active` follows the established `pill--published` /
     `pill--design` pattern)
   - A new theme variant rendered conditionally via CSS (e.g.
     `portrait-img--dark` / `portrait-img--light`)
   - A simple data prop being added (the kind of prop the component
     already takes — papers, posts, current)

   **Create a new component (don't extend) when the change would require:**
   - A new mode-switching prop (`compact: bool`, `variant: 'detailed' |
     'minimal'`, `layout: ViewMode`) — no existing component does this
   - Conditional rendering in the Dart body that branches the layout,
     not just the content (existing conditionals are limited to
     empty-state checks and bilingual display)
   - More than ~25% of the component body being unique to the new variant
   - Different responsive behaviour (different breakpoints, different
     mobile layout)

   The codebase pattern: extensions live in CSS, not Dart. If the change
   can be expressed as a class modifier or a CSS variable override, extend.
   If it needs Dart-side branching, create new.
3. **Is the new thing only used inside one existing section?** → INLINE it
   as private to that section first. Only extract to its own file when a
   second consumer appears.
4. **None of the above?** → Create a new component file. Choose role
   (atom / section / chrome / layout) BEFORE writing code. Add a
   `/// Role: <role>` and `/// <purpose>` docstring at the top. Update
   this file's inventory table.

## Worked examples

- **Add `pill--draft` for unpublished posts** → 3 lines of CSS for
  the new colour, zero Dart changes. Follows the established
  `pill--published` / `pill--design` / `pill--active` pattern.
  **EXTEND.**
- **Add a "compact" mode to `WritingList` that hides excerpts** → would
  require a `compact: bool` prop, conditional rendering of the excerpt
  block, possibly different spacing tokens. No existing component has a
  mode-switching prop. **CREATE** a new component (e.g.
  `WritingListCompact`) or extract a shared core if both versions are
  needed.
- **Add a 4th `card--*` status variant** → matches the existing pattern
  exactly. **EXTEND.**
- **Add a card layout where the image is on the right instead of below**
  → Dart-side layout change, not a CSS-only variant. **CREATE** new
  component.

## Constraints

- No inline styles in Dart — use CSS classes.
- New CSS classes go in `web/styles.css` (public) or `web/admin.css` (admin).
- New CSS rules reference semantic or component tokens, never primitives
  directly (see `web/tokens/TOKENS.md`).
- When adding a new component file, update the inventory table above.

For the design philosophy and token rules, see `/DESIGN.md`.
