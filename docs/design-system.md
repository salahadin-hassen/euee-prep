# EUEE Prep — Design System (Contract)

Status: **Contract only.** Defines the shape and names of design tokens so `core/design/` (Milestone 4) has something concrete to implement against. Actual values (brand colors, final font choice) are placeholders here, tunable later without changing any call site, since screens will always reference token *names*, never hardcoded values (Decision 018).

---

## Colors

| Token | Purpose |
|---|---|
| `colorPrimary` | Primary brand/action color |
| `colorSecondary` | Secondary accent |
| `colorBackground` | Screen background |
| `colorSurface` | Card/elevated surface background |
| `colorError` | Error states, incorrect answers |
| `colorSuccess` | Success states, correct answers |
| `colorWarning` | Locked/pending states (e.g. unpurchased subject) |
| `colorTextPrimary` | Primary text |
| `colorTextSecondary` | Secondary/muted text |
| `colorBorder` | Dividers, input borders |
| `colorDisabled` | Disabled controls |

Actual hex values are a pending brand decision, not defined here — placeholder values are acceptable for Milestone 4's implementation and swappable later with no call-site changes.

## Typography

| Token | Purpose |
|---|---|
| `typeDisplay` | Onboarding/hero text |
| `typeHeading1` / `typeHeading2` / `typeHeading3` | Screen and section headings |
| `typeBody` | Default body text |
| `typeCaption` | Secondary/small text |
| `typeButtonLabel` | Button text |

Font family: system default until a brand font is chosen — not a blocker for implementation.

## Spacing

| Token | Value (px) |
|---|---|
| `spaceXs` | 4 |
| `spaceSm` | 8 |
| `spaceMd` | 16 |
| `spaceLg` | 24 |
| `spaceXl` | 32 |
| `spaceXxl` | 48 |

## Radius

| Token | Value (px) |
|---|---|
| `radiusSm` | 4 |
| `radiusMd` | 8 |
| `radiusLg` | 16 |
| `radiusFull` | 999 (pill/circular) |

## Animation durations

| Token | Value (ms) |
|---|---|
| `durationFast` | 150 |
| `durationMedium` | 250 |
| `durationSlow` | 400 |

## Component variants (contract only — no implementation)

* **Buttons:** `primary`, `secondary`, `text` (ghost), `destructive`.
* **Cards:** `default`, `elevated`, `outlined`. Used for subject tiles, resource cards, locked-state previews.

---

## Out of scope for this contract

Actual widget implementation (`buttons.dart`, `cards.dart`, etc. in `core/design/`) — that's Milestone 4. This document only fixes the names and shape so that milestone isn't inventing token names on the fly.