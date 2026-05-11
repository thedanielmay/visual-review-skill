# Slide-deck specifics

Use this reference when the input is a slide deck (typically A4 landscape or 16:9, presentation-style, one logical "slide" per page).

The universal Tier 1-3 checklist in SKILL.md still applies. This file adds slide-specific checks and overrides defaults where slide conventions differ from documents.

## Page geometry assumptions

Default assumed page sizes for slides (override from `metadata.json` if different):
- A4 landscape: 297×210mm
- 16:9 widescreen: 1920×1080px (≈ 13.33×7.5in at 144 DPI)
- 4:3 standard: 1024×768px

If the deck uses a custom size, note it in the report header so the reader knows what "edge" means.

## Tier 1 (slide-specific) — ship-blockers

Add these to the universal Tier 1 checks:

- **Title clipping in display type.** Headings at 40pt+ are particularly vulnerable to right-edge clipping. Inspect every title slide and section divider.
- **Speaker-notes leak.** If the renderer is configured to hide speaker notes but they appear on a slide, that's Tier 1.
- **Build artefacts.** Half-revealed animations, fragments showing in their pre-build state, "appear on click" elements visible at slide load.
- **Slide-master breakthrough.** Body content overlapping with master elements (logo, page number, divider rule) on any slide.
- **Cross-slide layout regression on a single slide.** Slide 7 has a structurally different layout from slides 6 and 8 — usually accidental (a copy-paste error or a CSS override).

## Tier 2 (slide-specific) — typography

- **Title length variance.** Titles wrapping to 3+ lines on some slides while others are 1 line — pick a length budget and flag titles that exceed it.
- **Bullet density.** Slides with 8+ bullets are usually a structural problem; flag as `possible` Tier 2.
- **Body type smaller than 14pt at 16:9.** Read-distance calculation: anything below ~14pt is unreadable at typical projection distance.
- **Numbers split across line break.** "$1.2 / M" on two lines.

## Tier 3 (slide-specific) — layout

- **Eyebrow → rule → title pattern consistency.** If the deck establishes a pattern (eyebrow text, then a thin rule, then a heading) on early slides, every body slide should follow it. Flag missing eyebrows as drift, not absence.
- **Footer composition.** If the footer is "[deck name] · Page N of M", every body slide should have it; check the page count is correct.
- **Section divider style.** Section dividers should be visually distinct from body slides (no eyebrow, no footer, larger type, often coloured background). If a section divider looks like a body slide, flag it.
- **Title position drift.** Title baseline y-coordinate should be consistent across body slides; drift of >2mm is `likely` accidental.

## Tier 4 (slide-specific) — brand

- **Logo present on every body slide, absent on title and section dividers.** (Or whichever convention this deck establishes — match it.)
- **Colour palette compliance.** Sample inks used on each slide. Surface any colour not in the brand palette as `likely` brand drift.
- **Image treatment consistency.** If photos on slide 3 have rounded corners and a subtle shadow, photos on slide 9 should too.

## Slide-specific don't-flag list

These are NOT findings on slides:

- Title slide having no footer or page number — that's the convention.
- Section divider using a coloured background or a different layout — that's the point.
- A "thank you" or contact slide with sparse content — intentional whitespace is feature, not bug.
- Build/animation slides that don't make sense as static frames (the deck was designed for a presenter who clicks through). If the user supplies a slide deck for review *as a static PDF*, you can flag this once at the top ("this deck has presenter animations — some slides may look incomplete in static export") but don't repeat per slide.

## What to ask the user before reviewing a deck

If unclear:
- "Is this for a live presentation (presenter clicks through) or for distribution as a static PDF?" Affects whether to flag build-state artefacts.
- "Who's the audience — internal or external?" Affects how strict to be on brand drift.
- "Is there a brand template or previous deck I can diff against?"

Do not ask all three. Pick the most relevant one — usually the first.
