# visual-review

A Claude Code skill that performs visual QA on rendered documents — catching layout defects, clipped content, typographic problems, and brand drift that human reviewers routinely miss.

## Overview

`visual-review` renders PDFs and HTML pages at 300 DPI and walks through them the way a careful designer would: looking for things that will embarrass the user if shipped. It operates at machine scale and consistency, surfacing findings that are easy to miss at fit-to-page zoom — orphan border-tops (~1–2 px), footer overprint, clipped table rows, empty right columns — and reporting them in an action-first HOLD / FIX IF TIME / NOTE format so the user always knows what must be fixed before a document can ship.

The skill runs in two modes: **Quick Pass** (Phases 0–3 + 8–9, ~5–10 min for ≤20 pages, the default) and **Full Review** (all phases, requires editable source + shell access, ~30–60 min). When no rendering environment is available it falls back to a labelled text-only pass covering content issues only.

Version 2.0.0 adds a press-readiness checklist, Paged.js structural pattern detection, form-aware checks, and conditional stack assessment.

## When to use it / Triggers

Invoke this skill whenever you want to visually inspect a rendered artefact:

- Explicit requests: "check this PDF for glitches", "review my deck", "proof this report", "is this ready to send?", "visual QA", "does this look right?"
- After generating or modifying a PDF, slide deck, HTML report, brochure, or book — even without an explicit request.
- Before sending any client-facing document.

The skill also understands document type: slide decks, books/manuscripts, and multi-page reports each trigger a type-specific checklist (Phase 5) on Full Review.

## What it checks

**Universal Tier 1 — ship-blockers**
- Content clipped at any page edge (with 8 mandatory bottom-edge checks: sentence completion, box border completion, column completion, footer visibility, footer/header content clearance, major section opener page-break, flowing section footer collision)
- Text overrunning its container; overlapping elements; off-page elements; missing/broken images
- Font fallback, low-DPI raster assets, body text below legibility floor
- Table/list row counts differing between source and render
- Step/page/count indicators that don't match the actual document

**Universal Tier 2 — typography, form semantics, density**
- Orphans, awkward line breaks, mid-word hyphenation, heading hierarchy violations
- Form-field checks: doubled checkboxes, misaligned fields, wrap-fragile chip rows
- Background and contrast legibility (brand swatches at full saturation on panel fills, hairlines that disappear on tinted backgrounds)
- Density imbalance — cramped vs. sparse pages compared to sibling median

**Universal Tier 3 — layout rhythm**
- Baseline drift, inconsistent margins, rule line inconsistency, logo/footer position drift across pages

**Type-specific (Full Review)**
- Slide decks: `references/slides.md`
- Books/manuscripts: `references/books.md`
- Multi-page reports/proposals: `references/reports.md`

**Rendering environment**
- Preferred: `pdftoppm` (poppler) at 300 DPI — mandatory, non-negotiable
- HTML fallback: Playwright + Chromium
- Phase 0 checks both and declares the render method before any work begins

## Installation

This is a Claude Code plugin. Install via the Claude Code plugin registry or by cloning this repo and referencing the plugin manifest at `.claude-plugin/plugin.json`.

Once installed, invoke the skill with:

```
/visual-review
```

or let it trigger automatically when you produce a rendered document.

## What's inside

```
SKILL.md                              Top-level skill definition (frontmatter + full workflow)
.claude-plugin/plugin.json            Plugin manifest (name, version, author, keywords)
skills/visual-review/
  SKILL.md                            Skill entrypoint (mirrors root SKILL.md)
  references/
    slides.md                         Slide-deck type-specific checks
    books.md                          Book/manuscript checks (KDP, print, bleed/safe area)
    reports.md                        Multi-page report/proposal checks
    house-rules.md                    Style rules applied in Phase 7 mechanical fixes
    confidence-rubric.md              Full confidence labelling guide (confident/likely/possible)
    pagedjs.md                        Paged.js structural patterns and known footguns
```

## Status

**v2.0.0** — active, in use. Changelog:

- **v2.0.0** — stack assessment integration, expert-panel fixes, commercial press-readiness checklist
- **v1.1.0** — expanded checks, 300 DPI mandate, Paged.js structural patterns
- **v1.0.0** — initial release

Author: Daniel May (`daniel@thedanielmay.com`)
