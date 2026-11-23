# visual-review

A Claude Code skill that performs visual QA on rendered documents, catching layout defects, clipped content, typographic problems, and brand drift that human reviewers routinely miss.

## Overview

`visual-review` renders PDFs and HTML pages at 300 DPI and walks through them the way a careful designer would: looking for things that will embarrass the user if shipped. It operates at machine scale and consistency, surfacing findings that are easy to miss at fit-to-page zoom, orphan border-tops (~1-2 px), footer overprint, clipped table rows, empty right columns, and reporting them in an action-first HOLD / FIX IF TIME / NOTE format so the user always knows what must be fixed before a document can ship.

The skill runs in two modes: **Quick Pass** (Phases 0-3 + 8-9, ~5-10 min for 20 pages or fewer, the default) and **Full Review** (all phases, requires editable source and shell access, ~30-60 min). It tiles 300 DPI renders so the model sees full detail, uses Read as an image fallback, and falls back to a labelled text-only pass only when no image view exists.

## When to use it / Triggers

Invoke this skill whenever you want to visually inspect a rendered artefact:

- Explicit requests: "check this PDF for glitches", "review my deck", "proof this report", "is this ready to send?", "visual QA", "does this look right?"
- After generating or modifying a PDF, slide deck, HTML report, brochure, or book, even without an explicit request.
- Before sending any client-facing document.

The skill also understands document type: slide decks, books/manuscripts, and multi-page reports each trigger a type-specific checklist (Phase 5) on Full Review.

## What it checks

**Universal Tier 1, ship-blockers**
- Content clipped at any page edge (with 8 mandatory bottom-edge checks: sentence completion, box border completion, column completion, footer visibility, footer/header content clearance, major section opener page-break, flowing section footer collision)
- Text overrunning its container; overlapping elements; off-page elements; missing/broken images
- Font fallback, low-DPI raster assets, body text below legibility floor
- Table/list row counts differing between source and render
- Step/page/count indicators that do not match the actual document

**Universal Tier 2, typography, form semantics, density**
- Orphans, awkward line breaks, mid-word hyphenation, heading hierarchy violations
- Form-field checks: doubled checkboxes, misaligned fields, wrap-fragile chip rows
- Background and contrast legibility (brand swatches at full saturation on panel fills, hairlines that disappear on tinted backgrounds)
- Density imbalance, cramped vs. sparse pages compared to sibling median

**Universal Tier 3, layout rhythm**
- Baseline drift, inconsistent margins, rule line inconsistency, logo/footer position drift across pages

**Type-specific (Full Review)**
- Slide decks: `references/slides.md`
- Books/manuscripts: `references/books.md`
- Multi-page reports/proposals: `references/reports.md`

**Rendering environment**
- Preferred: `pdftoppm` (poppler) at 300 DPI, with tiled views
- HTML: `playwright pdf <url> <file>`, then render the resulting PDF
- Fallback: Read shows PDF pages as images at roughly 100 DPI
- Phase 0 checks both renderers and declares the render method before any work begins

## Install

Install from the marketplace in this repo:

```
/plugin install visual-review --marketplace thedanielmay/visual-review-skill
```

Or link a local checkout into your skills folder:

```
ln -s ~/projects/agent-tools/skills/visual-review-skill/skills/visual-review ~/.claude/skills/visual-review
```

Once installed, invoke the skill with:

```
/visual-review
```

or let it trigger automatically when you produce a rendered document.

## What's inside

```
.claude-plugin/plugin.json            Plugin manifest (name, version, author, keywords)
skills/visual-review/
  SKILL.md                            THE skill: the only copy, and the file ~/.claude/skills/visual-review resolves to
  references/
    slides.md                         Slide-deck type-specific checks
    books.md                          Book/manuscript checks (KDP, print, bleed/safe area)
    reports.md                        Multi-page report/proposal checks
    house-rules.md                    Optional project style file format
    checklist-core.md                 Universal checks for every page
    checklist-forms.md                Form and colour checks
    checklist-cover.md                Cover page checks
    density.md                        Sparse and cramped page analysis
    print-preflight.md                Metadata and print HOLD rules
    worked-examples.md                CSS causes behind visual symptoms
    handoff.md                        Optional session handoff block
    confidence-rubric.md              Full confidence labelling guide (confident/likely/possible)
    pagedjs.md                        Paged.js structural patterns and known footguns
  evals/
    README.md                         How to run the suite
    clipping/, overlap/, runt/        Cases with planted defects and graders
```

## Status

See [CHANGELOG.md](CHANGELOG.md) for what changed in each release. The current version is in `.claude-plugin/plugin.json`.

