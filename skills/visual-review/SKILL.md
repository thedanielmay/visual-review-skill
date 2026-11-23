---
name: visual-review
description: Use when the user asks to QA, review, proof, or visually inspect a rendered document, PDFs, slide decks, books, reports, brochures, or HTML pages. Triggers on phrases like "check this PDF for glitches," "review my deck," "proof this report," "is this ready to send?", "visual QA," "does this look right?", or any time the user produces a rendered artefact and wants someone to look at it carefully. Catches clipped content, overflow, broken layout, typographic problems (orphans, hyphenation, dash policy), brand drift, and consistency issues across pages. Use proactively after the user generates or modifies a PDF/deck/report.
license: MIT
metadata:
  version: "2.2.0"
---

# Visual Review

Inspect a rendered document the way a careful designer would. Find what a reader would notice and what would embarrass the sender if shipped. Work at machine scale and with a consistency a tired person cannot match.

## What this skill is for

Review the visual output, not the source. The render is the source of truth. A clean HTML file that produces a clipped PDF is a broken document.

Surface non-visual problems you notice while reading. Put them under BEYOND VISUAL so the user can separate strict findings from bonus findings.

Out of scope:

- Accessibility tooling and WCAG contrast measurement.
- Rewriting prose. Flag a confusing sentence, but do not edit it.

## Modes

**Quick Pass** (default): Phases 0, 1, 2, 3, 8, 9.

- Runs: precondition gate, input ID, render, per-page pass, report, fix guidance.
- Skips: cross-page consistency, type-specific pass, reference diff, source fixes.
- Time: about 5 to 10 minutes for 20 pages or fewer.
- Report: HOLD, FIX IF TIME, NOTE, BEYOND VISUAL, SUPPRESSED FINDINGS. MECHANICAL FIXES is skipped. This skill writes no STACK section; Phase 1.5 hands off instead.

**Full Review**: Phases 0 to 9.

- Uses shell access. A read-only source skips Phase 7 and produces fix guidance only.
- Time: about 30 to 60 minutes, depending on page count.
- Adds CROSS-PAGE DRIFT and TYPE-SPECIFIC CHECKS to the report.

**Text-only pass** (fallback):

- Trigger: no renderer and no image view of the PDF.
- Runs content checks only. Every finding carries `[TEXT-INFERRED - not visually confirmed]`.
- Label the report as not a visual review.

When the user does not choose a mode, use Quick Pass.

## Workflow

```
0. Precondition gate
      |
1. Identify input
      |
1.5. Stack handoff (one line)
      |
2. Render and capture metadata
      |
3. Per-page visual pass (3A then 3B)
      |
      +--- Quick Pass exits to Phase 8
      |
4. Cross-page consistency
5. Type-specific pass
6. Diff against reference
7. Mechanical fixes (Full Review, editable source)
      |
8. Action-first report
9. Fix-guidance export
```

## Files in this skill and when to read them

Load a reference only when its trigger fires. Do not load all of them.

| File | Read when |
|---|---|
| `references/checklist-core.md` | Phase 3, for every page in every mode. |
| `references/checklist-forms.md` | The document is a fillable form or a branded artefact. |
| `references/checklist-cover.md` | Page 1 carries a cover or title treatment. |
| `references/density.md` | Phase 3B, when comparing whitespace across pages. |
| `references/print-preflight.md` | Phase 2, for every PDF or HTML input. |
| `references/pagedjs.md` | Phase 2 metadata confirms Paged.js signals. |
| `references/confidence-rubric.md` | You need worked examples for a confidence label. |
| `references/slides.md`, `references/books.md`, `references/reports.md` | Phase 5, for the matching document type. |
| `references/worked-examples.md` | A Phase 3 symptom matches a known CSS pattern. |
| `references/house-rules.md` | The user opts in to a project style file in Phase 7. |
| `references/handoff.md` | The user asks for a session handoff block. |

## Phase 0: Precondition gate

Run this before other work. Show the results, then branch.

```bash
which pdftoppm 2>/dev/null && echo "pdftoppm: available" || echo "pdftoppm: NOT available"
playwright --version 2>/dev/null && echo "playwright: available" || echo "playwright: NOT available"
```

Show this summary:

```
Environment check:
  pdftoppm:   [available | NOT available]
  playwright: [available | NOT available]
  Source:     [editable | read-only | not provided]
  Mode:       [Quick Pass | Full Review | text-only]
  Context:    [client-facing | internal draft | print production]
```

**Ask one question when the request leaves both mode and context open:**

> "Quick Pass or Full Review? Default Quick Pass. Is this client-facing, an internal draft, or print production? Default internal draft."

If the request already names a mode or context, or asks directly for a report, ask nothing. Use Quick Pass and internal draft. State both in the report header.

**Ask nothing when the skill runs proactively.** Use Quick Pass, internal draft, and a document type inferred from the file name and structure. State those defaults in the report header.

**No command renderer available.** Use Read on the PDF. Read shows PDF pages as images. If Read cannot show the PDF, say one line: "No renderer is available. I can run a text-only pass for content issues only." Proceed with the text-only pass. Do not ask for a yes or no.

**Source is read-only.** Skip Phase 7. Put `Source: read-only` in the report header. Full Review then produces fix guidance only.

**Large Full Review.** If the document has more than 50 pages, warn once. Suggest Quick Pass or review in 20-page sections.

### HTML overflow preflight (when HTML source is available)

If a page uses a fixed height or `overflow: hidden`, run this check before export:

```js
// Serve over HTTP first when file:// is blocked:
// python3 -m http.server 7823 --directory <folder>
await page.goto('http://localhost:7823/<path-to-html>');
const overflowReport = await page.evaluate(() => {
  const results = [];
  document.querySelectorAll('.page, [class*="page"]').forEach((page, i) => {
    const overflow = page.scrollHeight - page.clientHeight;
    const label = page.getAttribute('data-label') || page.id || `Element ${i + 1}`;
    const longForm = page.classList.contains('long-form') ||
                     page.style.height === 'auto' ||
                     page.hasAttribute('data-long-form');
    if (overflow > 0 && !longForm) {
      results.push({ index: i + 1, label, overflowPx: overflow });
    }
  });
  return results;
});
```

Every page with `overflowPx > 0` is a HOLD finding. Check pages within 10 px visually as well. A long-form page uses `height: auto` in print and is exempt.

## Phase 1: Identify input

- What was given: a PDF, an HTML file, both, or a URL?
- What kind of document: slides, book, report, brochure, or single page?
- Is there a reference document or brand guide to diff against?
- Is source available for source pointers and fixes?

When the user invoked the skill and the document type is unclear, ask one question. When the skill runs proactively, infer the type and state the inference in the report.

## Phase 1.5: Stack handoff

Do not run a local stack survey. If the user asks about the rendering stack, or the Producer is wkhtmltopdf, hand off to `visual-stack-review` when that skill is installed. Otherwise note the Producer in the report and continue. Never point the user at a skill they do not have.

## Phase 2: Render and capture metadata

Set the output folder once. For HTML input, `PDF` points at the `output.pdf` made below.

```bash
OUT=review_render
mkdir -p "$OUT/pages"
```

### PDFs

Render the supplied PDF at 300 DPI. A4 portrait at 300 DPI is 2480 by 3508 pixels, larger than the image limit on the long edge. Read the full-page renders first.

```bash
PDF=<path to the input PDF>
pdftoppm -png -r 300 "$PDF" "$OUT/pages/page"
```

**Full Review, tile every page.** Tiles show the 1 px detail the full page loses.

```bash
mkdir -p "$OUT/tiles"
MAX=2500
for PAGE in "$OUT"/pages/page-*.png; do
  BASE=$(basename "$PAGE" .png)
  W=$(identify -format '%w' "$PAGE")
  H=$(identify -format '%h' "$PAGE")
  COLS=$(( (W + MAX - 1) / MAX ))
  ROWS=$(( (H + MAX - 1) / MAX ))
  TW=$(( (W + COLS - 1) / COLS ))
  TH=$(( (H + ROWS - 1) / ROWS ))
  magick "$PAGE" -crop "${TW}x${TH}+0+0" +repage "$OUT/tiles/${BASE}-t%d.png"
done
```
Read every tile. Keep the tile name in any finding that uses it. Re-tile with a 20 px overlap when a defect sits on a seam.

**Quick Pass, crops on demand.** Crop all four edges only on pages where something looks wrong. Set `CROP_PAGES` to those pages. Full Review crops every page. Read each page's own size first so portrait footers are checked.

```bash
mkdir -p "$OUT/crops"
CROP_PAGES="$OUT"/pages/page-*.png
for PAGE in $CROP_PAGES; do
  BASE=$(basename "$PAGE" .png)
  W=$(identify -format '%w' "$PAGE")
  H=$(identify -format '%h' "$PAGE")
  magick "$PAGE" -crop "${W}x177+0+0" +repage "$OUT/crops/${BASE}-top.png"
  magick "$PAGE" -crop "${W}x118+0+$((H - 118))" +repage "$OUT/crops/${BASE}-bottom.png"
  magick "$PAGE" -crop "177x${H}+0+0" +repage "$OUT/crops/${BASE}-left.png"
  magick "$PAGE" -crop "177x${H}+$((W - 177))+0" +repage "$OUT/crops/${BASE}-right.png"
done
```

**No `magick`.** Skip tiles and crops. Review the full-page renders. Do a short zone check by eye: top 15 mm for orphan rules, bottom 10 mm footer band, column gutters, and rules crossing glyphs. State the lower detail in the report.

**No `pdftoppm`.** Use Read on the PDF at roughly 100 DPI. State the lower detail in the report header. When Read cannot show the PDF, run the text-only pass.

### HTML

Use `playwright pdf` with the official CLI. Then render the resulting PDF with the same commands.

```bash
playwright pdf "file://$PWD/input.html" output.pdf
PDF=output.pdf
mkdir -p "$OUT/pages"
pdftoppm -png -r 300 "$PDF" "$OUT/pages/page"
```
Capture DOM bounding boxes with `page.evaluate()` when source mapping is needed.

If both HTML source and a supplied PDF are present, render the HTML fresh. Note in the report if the fresh render differs.

### Metadata (every mode)

Run the three tools on `PDF`: the input PDF, or the `output.pdf` made by the HTML step. `OUT` is the folder set at the start of this phase.

```bash
pdfinfo -box "$PDF" > "$OUT/metadata.txt"
pdffonts "$PDF" >> "$OUT/metadata.txt"
pdfimages -list "$PDF" >> "$OUT/metadata.txt"
```
Load `references/print-preflight.md` now. Apply its HOLD rules in every mode, including Quick Pass.

## Phase 3: Visual pass

Phase 3 has two steps in sequence.

- **3A, page level:** one page at a time. Clipping, font fallback, overlap, image quality, typography.
- **3B, batch comparison:** after all pages are seen. Density, baseline rhythm, margin drift.

Quick Pass runs both. Full Review runs both and feeds Phase 4. The 3A and 3B split is a work sequence, not a report structure. Write one unified findings list in Phase 8.

Load `references/checklist-core.md` now. Load `references/checklist-forms.md` for forms and branded artefacts. Load `references/checklist-cover.md` when page 1 is a cover.

**Tier to action mapping:**

| Tier | Default | Client-facing | Internal draft |
|---|---|---|---|
| Tier 1, lost content | HOLD | HOLD | HOLD |
| Tier 2, typography | FIX IF TIME | FIX IF TIME | NOTE |
| Tier 3, layout | NOTE | FIX IF TIME | NOTE |

Use the table. Do not promote a finding outside its row. HOLD stays reserved for the problems listed in Phase 8: lost content, unembedded fonts, print resolution and bleed, and wrong facts. A user can downgrade a finding after reading the report.

**Enumeration pass.** For each page, list every anomaly first. For each one give the page and region in words, the category, an action estimate, and one concrete sentence. Then classify the list. Enumeration before classification keeps the sweep wide.

**Finding format:**

```
Page: N, Region: <words>
What is wrong: <concrete description>
Suggested fix: <one or more options>
Source pointer: <file:line when available>
Confidence: confident | likely | possible
```

Use `references/confidence-rubric.md` for worked examples. HOLD findings need the strongest evidence. NOTE findings can be one line.

**Locked content.** Some documents pin canonical strings, such as legal disclaimers, definitions, or prices. Signs include `<!-- LOCKED -->` comments, a project note, or a stated "single source of truth". Compare any locked string in scope with its canonical version, character for character. A one-character drift is a HOLD finding because it creates a silent contradiction. If the canonical source is absent, report a possible HOLD and ask the user to confirm.

**Credit and count labels.** Check every "Step 3 of 5" or "Page 7 of 10" against the rendered count. A mismatch is a FIX IF TIME finding because the reader expects the count to match.

### Phase 3B: batch comparison

After 3A, scan the pages together:

- **Bottom dead-whitespace gap:** note the gap above the footer on each body page and the visual median. A gap over twice the median is excessive whitespace. A gap under half the median is cramping.
- **Footer y-position:** note drift against neighbouring pages.
- **Body text size:** spot-check one paragraph per page for visible size drift.

Load `references/density.md` when a page looks sparse or cramped. It separates false sparseness from real sparseness.

### Finding consolidation

Before Phase 8, group findings that share a visual description and a root cause on three or more pages. Give the group a page list, one shared fix, and a short sub-note for each page with a local variation. Keep separate any findings with the same symptom but different causes. Do not hide an outlier to make the list tidy.

**Quick Pass exits here.** Go to Phase 8. Full Review continues.

## Phase 4: Cross-page consistency (Full Review)

Measure across all pages and report unexpected drift:

- Logo bounding box.
- Footer y-position and height.
- Body text size from one paragraph per page.
- Left, right, and top body margins.
- Presence or absence of eyebrow labels.
- Rule line colour, width, and position.
- Heading-block gap rhythm across pages that share an eyebrow, heading and lead structure.
- Header clearance across section openers, both the lower and upper bound.

Skip structurally different pages, such as covers and dividers. Use `references/confidence-rubric.md` to separate intent from drift.

## Phase 5: Type-specific pass (Full Review)

Load the reference for the type identified in Phase 1:

- Slides: `references/slides.md`
- Book or manuscript: `references/books.md`
- Report or proposal: `references/reports.md`

## Phase 6: Diff against reference (Full Review)

If the user supplied a previous version or a brand guide, Read both rendered sets and describe the differences per page. Report unexpected drift. Do not treat an intentional iteration as a finding.

## Phase 7: Mechanical fixes (Full Review, editable source)

Run fixes after the visual pass so the original render stays available for comparison.

Gates:

- The source must be editable.
- The user must approve the change list before any edit.
- Quick Pass skips this phase.

**Default dash rule.** Check dash use within the document. If the same role uses em dashes in one place and en dashes or hyphens in another, flag the inconsistency. Never rewrite an en dash in a numeric range. It is correct there. Never rewrite punctuation to match one person's taste.

**Optional project rules.** If the project supplies `HOUSE_RULES.md`, read `references/house-rules.md` for the file format. Apply its rules only after the user approves them. If no such file exists, use the default dash rule only.

Apply approved edits with the Edit tool. Log each change to `mechanical_fixes.log` beside the source as `file:line | before | after`. Re-render after the edits. Report any new findings as `[introduced by mechanical fix]`. If no source is available, skip the phase and say so.

## Phase 8: Action-first report

### Header

```
# Visual Review: <document name>

Rendered: <timestamp>, <page count> pages
Render method: [pdftoppm 300 DPI with tiles | Read image view | text-only]
Mode: [Quick Pass | Full Review]
Source: [editable at <path> | read-only | not provided]
Context: [client-facing | internal draft | print production]
Renderer: [Paged.js | non-Paged.js | not checked]
Mechanical fixes: [<count> in log | none | skipped]
```

If the render method is text-only, place this line after the header:

```
> TEXT-ONLY PASS: visual issues not assessed.
```

### Buckets

**HOLD, fix before sending.** The recipient would reject the document, or the document fails a hard standard. Use HOLD for lost content, unembedded fonts, low-resolution or missing bleed in print, and wrong facts.

Context rules:

- Client-facing: count mismatches and pricing ambiguity are FIX IF TIME.
- Internal draft: the same findings are FIX IF TIME or NOTE.
- Print production: font not embedded, low-resolution image, or missing bleed is HOLD.
- Client-facing screen PDF: font not embedded is FIX IF TIME.

Each finding:

```
### HOLD: <one-line summary>
- Page: N, Region: <description>
- Confidence: confident | likely | possible
- What is wrong: <concrete description>
- Suggested fix: <list options>
- Source pointer: <file:line if available>
```

**FIX IF TIME.** Reduces quality but does not block delivery. Typography, density imbalance, and visual inconsistency. Use the same format.

**NOTE FOR NEXT VERSION.** Valid polish to log but not fix now.

**TYPE-SPECIFIC CHECKS (Full Review).** Findings from Phase 5.

**CROSS-PAGE DRIFT (Full Review).**

```
### Drift: <item>
Pages affected: N, M, O
Expected: <majority value>
Observed: <variant value>
Likely cause: accident or intent, verify
```

**STACK (handoff only).** This report has no STACK section. Phase 1.5 hands off to `visual-stack-review` when the user asks about the stack or the Producer is wkhtmltopdf and that skill is installed. Otherwise note the Producer and the renderer in the report header and continue.

**BEYOND VISUAL (all modes).** Non-visual issues found during review, clearly marked out of scope.

**SUPPRESSED FINDINGS (all modes).** List every suppressed finding. Never suppress in silence. List an unknown ignore type here with the word `unknown type`.

```
[suppressed] page:N <finding-type> - rule: "<exact rule text>"
[stale rule] page:N <finding-type> - no matching finding this run
[unknown type] page:N <finding-type> - rule: "<exact rule text>"
```

**MECHANICAL FIXES APPLIED (Full Review).** List each `file:line | before | after`.

### End of report

```
Want to act on any of these?
- Reply with finding IDs, for example "HOLD-1, FIX-3", for fix guidance.
- Reply "export fix-guidance" for the full list.
- Reply "ignore [finding-ID]" to get a .visualreviewignore entry.
- Reply "output handoff block" for the optional YAML handoff block.
- Re-review requires a fresh invocation on the updated source.
```

## Phase 9: Fix-guidance export

Output one entry per HOLD and FIX IF TIME finding. This phase applies no fixes and re-renders nothing. A fresh invocation on the updated source is the correct re-review pattern.

```
ID: <finding-id>
Page: <N>
Region: <description>
Action: <one-line fix>
Options:
  A. <option A>
  B. <option B>
Source: <file:line if available>
Confidence: <confident | likely | possible>
```

Collect the entries under `## Fix-guidance export`.

The optional handoff block is in `references/handoff.md`. Emit it only on request.

## Confidence labels

- `confident`: provable from the render or metadata. A person looking at the same tile would agree.
- `likely`: clear visual signal, but the design intent is unknown.
- `possible`: weak or subjective signal, surfaced for awareness.

Confidence is not severity. A `possible` HOLD still belongs in HOLD. Default down a level when uncertain.

## What to ignore

Suppress only two kinds of finding:

- Aesthetic preferences with no rule violation.
- Findings covered by a `.visualreviewignore` rule.

For an intentional-looking design choice, flag it as `possible` with a note. The user can dismiss it in two seconds. Silence risks missing a real defect.

## .visualreviewignore

If the project has a `.visualreviewignore` file at its root, read it and skip matching findings. One rule per line:

```
# Title slides use a different layout
page:1 layout-drift

# Dividers have no footer
page:5,9,13 missing-footer
```

Valid types: `layout-drift`, `missing-footer`, `missing-eyebrow`, `overflow`, `orphan`, `density-imbalance`, `brand-drift`, `rule-overlap`, `text-inferred`.

The file belongs to the user and is authoritative. Report every suppressed finding. Check each rule at the end of the review. If a rule matched no finding, report a stale rule. If a type is not in the list, report it as an unknown type and keep the finding.

When the user asks to ignore a finding, generate `page:N <finding-type>` and ask them to append it to `.visualreviewignore` at the project root.

## Metadata reasoning

Treat every metadata flag as a hypothesis and check it against the render. `references/print-preflight.md` holds the flags, their meaning, and the print HOLD rules. Do not paste raw metadata into the report.

## Working principles

- Look at every page. A skipped page is the page with the bug.
- Describe what you see, not what you assume.
- Reference the tile or crop that supports a finding. Save crops when a renderer is available. When it is not, describe the region in words.
- Suggest fixes and leave the decision to the user.
- When you cannot apply a fix, say so and give the options.
- Re-render after a Phase 7 source fix. Phase 9 exports guidance and does not re-render.
- Put HOLD findings first. A reader must stop after HOLD and know whether the document can ship.

## When to bail

Stop and ask the user when:

- The PDF will not render or is password protected.
- The document type is unclear and the type-specific check matters, when the user invoked the skill.
- A fix you are about to apply can be wrong.
- Fixes produce more new findings than they resolve.
