---
name: visual-review
description: Use when the user asks to QA, review, proof, or visually inspect a rendered document — PDFs, slide decks, books, reports, brochures, or HTML pages. Triggers on phrases like "check this PDF for glitches," "review my deck," "proof this report," "is this ready to send?", "visual QA," "does this look right?", or any time the user produces a rendered artefact and wants someone to look at it carefully. Catches clipped content, overflow, broken layout, typographic problems (orphans, hyphenation, dash policy), brand drift, and consistency issues across pages. Use proactively after the user generates or modifies a PDF/deck/report, even if they don't explicitly request review.
---

# Visual Review

You are about to inspect a rendered document the way a careful designer would: looking for things that will embarrass the user if shipped. Your job is to catch what the eye catches, but at machine scale and with consistency a tired human can't match.

## What this skill is for

Reviewing the *visual output* of a document — what it looks like when rendered, not what the source code says. The render is the source of truth. A flawless HTML file that produces a clipped PDF is still a broken document.

## Modes

**Quick Pass** (default): Phases 0, 1, 2, 3, 8, 9.
- What runs: precondition gate + input identification + render + per-page visual pass + report + fix-guidance
- What skips: cross-page consistency, type-specific pass, diff against reference, mechanical fixes
- Time: ~5–10 min for ≤20 pages
- Report sections: HOLD, FIX IF TIME, NOTE, BEYOND VISUAL, SUPPRESSED FINDINGS, MECHANICAL FIXES (skipped)
- Best for: time-constrained review, locked PDFs, first pass on any document, sandboxed environments

**Full Review**: Phases 0–9 (all phases).
- Requires: editable source, shell access (pdftoppm or Playwright)
- Time: ~30–60 min depending on page count
- Report sections: all sections including CROSS-PAGE DRIFT and TYPE-SPECIFIC CHECKS
- Best for: final pre-delivery QA, print production, decks with known brand drift

**Text-only pass** (fallback when no rendering available):
- Triggered by: Phase 0 detecting no pdftoppm and no Playwright
- What runs: content issues only — no visual findings
- Every finding labelled: `[TEXT-INFERRED — not visually confirmed]`
- Not a visual review — label the report accordingly

Select mode in Phase 0. Quick Pass is the default. Full Review requires explicit opt-in.

## Scope — start broad, narrow later

Visual review is the *primary* job. But while you're reading the document carefully, you'll often notice issues adjacent to visual quality: a TOC entry pointing at the wrong page, a spec contradicting itself between sections, a citation that doesn't resolve, a price that disagrees with the price two pages later. **Don't suppress those findings.** A reviewer who notices a real problem and stays silent because "that's not visual" is doing the user a disservice. Surface them under a separate **"Beyond visual"** section in the report so the user can see at a glance what's strict-scope and what's bonus.

The only things genuinely out of scope:
- **Accessibility tooling** (screen-reader behaviour, WCAG contrast measurement) — different concern, different skill.
- **Copy editing prose** — you can flag a confusing sentence, but don't rewrite it.

If you're unsure whether something is in scope, surface it. The user can ignore noise faster than they can recover from a missed HOLD.

## The workflow

You walk through these phases in order. Don't skip phases unless explicitly told the input is unsuitable for that phase (e.g. no source available → skip Phase 7 — mechanical fixes).

```
0. Precondition gate  →  1. Identify input  →  2. Render + capture metadata
                                    ↓
           [Quick Pass: skip to Phase 8 after Phase 3]
                                    ↓
3. Per-page visual pass  →  4. Cross-page consistency  →  5. Type-specific pass
       ↓
6. Diff against reference  →  7. Mechanical fixes (Full Review + editable source only)
       ↓
8. Action-first report  →  9. Fix-guidance export
```

### Phase 0 — Precondition gate (Quick Pass + Full Review)

Run before any work begins. Surface the results to the user, then branch.

```bash
# Check rendering environment
which pdftoppm 2>/dev/null && echo "pdftoppm: available" || echo "pdftoppm: NOT available"
npx playwright --version 2>/dev/null && echo "playwright: available" || echo "playwright: NOT available"
```

Present a summary:

```
Environment check:
  pdftoppm:   [available | NOT available]
  playwright: [available | NOT available]
  Source:     [editable | read-only | not provided]
  Mode:       [to be selected]
```

**Branch: no rendering available**

If both pdftoppm and playwright are unavailable, inform the user:

> "No rendering environment available. I can run a text-only pass covering content issues (TOC mismatches, cross-reference errors, factual contradictions) but cannot assess visual problems (clipping, overlaps, font fallback, density). Every finding will be labelled `[TEXT-INFERRED — not visually confirmed]`. This is not a visual review — proceed? [y/n]"

If yes: proceed but apply the text-only label to all findings. Skip Phase 3–7. Go to Phase 8 with a TEXT-ONLY PASS warning in the report header.

**Branch: source not editable**

If source is a locked PDF, client-delivered file, or otherwise not writable:
- Disable Phase 7 (mechanical fixes cannot run)
- Phase 9 output will be "fix-guidance only" (no source edits)
- Note in report header: `Source: read-only — mechanical fixes skipped`

**Mode selection (ask once)**

> "Quick Pass (Phases 0–3 + 8–9, ~5–10 min for ≤20 pages) or Full Review (all phases, requires editable source, ~30–60 min)? Default: Quick Pass."

Quick Pass skips Phases 4, 5, 6, and 7. Quick Pass report omits the CROSS-PAGE DRIFT and TYPE-SPECIFIC sections.

**If page count > 50 and Full Review selected:**

> "This document has [N] pages. Full Review on 50+ pages generates 35+ findings. The fix loop will not be reliable at this scale — consider Quick Pass or reviewing in 20-page sections."

Commit the mode and render-method to the report header before proceeding.

**HTML source overflow pre-flight (mandatory when HTML source is available)**

If the input includes an HTML source file with fixed-height pages (any page using `height: 210mm`, `height: 794px`, or `overflow: hidden` in print CSS), run the Playwright overflow audit BEFORE exporting to PDF:

```js
// Serve the HTML via local HTTP server first if file:// is blocked
// python3 -m http.server 7823 --directory <project-root>

await page.goto('http://localhost:7823/<path-to-html>');
const overflowReport = await page.evaluate(() => {
  const results = [];
  document.querySelectorAll('section.page, .page, [class*="page"]').forEach((page, i) => {
    const overflow = page.scrollHeight - page.clientHeight;
    const label = page.getAttribute('data-screen-label') || page.id || `Element ${i+1}`;
    const isLongForm = page.classList.contains('page--long-form') || 
                       page.classList.contains('long-form');
    if (overflow > 2 && !isLongForm) {
      results.push({ index: i+1, label, overflowPx: overflow });
    }
  });
  return results;
});
```

**Every page with `overflowPx > 0` is a guaranteed HOLD finding** — content will be silently clipped in the PDF. Do not proceed to PDF export without resolving or explicitly noting all overflow findings.

Pages within 10px of the boundary (0 < overflowPx ≤ 10) should also be checked visually in the PDF — Chrome's print rendering can clip content that appears to fit in screen mode due to rounding differences.

Note: `page--long-form` pages are excluded from this check because they intentionally overflow in screen mode and use `height: auto` in `@media print`.

### Phase 1 — Identify input

Ask yourself (and the user if unclear):

- **What was given?** A PDF path? An HTML file? Both (HTML source + rendered PDF)? A URL?
- **What kind of document?** Slide deck, book/manuscript, multi-page report, brochure, single page. This determines which `references/<type>.md` to load later.
- **Is there a brand reference?** A previous version, template, or brand-guidelines PDF to compare against?
- **Is source available?** If yes, source-mapping is possible (you can point at the line that produced the glitch, and you can apply mechanical fixes). If no, you can only describe page+region.

If any of this is ambiguous, ask one short clarifying question. Do not guess — guessing on doc type leads to applying the wrong reference checklist.

### Phase 2 — Render + capture metadata

**For PDFs**, use `pdftoppm` (poppler) — most accurate renderer, matches Adobe/Chrome:
```bash
pdftoppm -png -r 300 input.pdf output_dir/page
pdfinfo input.pdf > output_dir/metadata.txt
pdffonts input.pdf >> output_dir/metadata.txt
```
This produces `page-NN.png` (one per page) plus a metadata file with page dimensions, fonts (and whether they're embedded), page count.

**Render DPI requirement: 300 DPI — this is non-negotiable.**

Previous reviews at 200 DPI missed:
- Orphan `border-top` rules (~1–2px) appearing below the header gap on continuation pages — reads as a density artefact at 200 DPI, only clearly visible at 300 DPI
- Footer overprint — body text's last line sitting on top of footer text; two similarly-weighted layers merge visually at 200 DPI
- Callout boxes with clipped bottom borders (border reads as "page edge" at low DPI)
- Mid-sentence text endings (short last lines look natural at low resolution)
- Missing column content (absent right column reads as intentional whitespace)

Always use `-r 300` with pdftoppm. Never 130, never 150, never 200. The disk cost (≈2× over 200 DPI) is trivial; the cost of a missed finding is shipping broken pages.

**Zone-crop checks (mandatory — full-page view is insufficient).**

Reading each page at full A4 fit-to-screen scale misses defects that are only 1–4px at render resolution. After the full-page pass, perform explicit zone checks by mentally (or literally) cropping and examining these areas on every page:

1. **Top 15mm of content area** — look for any horizontal rule that is NOT the header rule. A second thin rule here is an orphan `border-top` from a fragmented CSS element. Easy to dismiss as image compression noise at full-page scale.
2. **Bottom 10mm of content area** — look for body text whose last line sits in the same horizontal band as the footer text. Footer overprint is subtle at full-page scale because the two text layers are similar weight and colour.
3. **Column gutter** — on two-column pages, check that both columns have content and that the gutter is consistent. An empty right column can read as intentional whitespace at small scale.
4. **Any page containing a table or rule-heavy layout** — zoom into each rule and confirm it does not overprint glyph baselines above or below it.

These are not optional spot-checks — they are mandatory for every page in the sweep.

**For HTML**, use Playwright + Chromium — same engine the document would render in for users:
```bash
npx playwright cr --headless --pdf=output.pdf input.html
# then pdftoppm the resulting PDF
```
Capture DOM bounding boxes via Playwright's `page.evaluate()` to map page regions back to source elements (this is what makes source-mapped findings possible).

**If shell access is not available (text-only mode):**

Do NOT use the Read tool as a visual rendering substitute. The Read tool extracts text and structure — it does not produce rendered images. A "visual review" that ran on text extraction is not a visual review.

When shell is unavailable, Phase 0 will have already declared text-only mode. Proceed to Phase 3 (per-page pass) with the constraint that every finding must be prefixed `[TEXT-INFERRED — not visually confirmed]` and must be limited to content issues (TOC errors, cross-reference mismatches, factual contradictions). Do not report visual findings you cannot see.

**If both HTML source and a rendered PDF are present**, render the HTML yourself fresh rather than trusting the supplied PDF — they may be out of sync. Note in the report if your fresh render differs from the supplied PDF.

### Phase 3 — Per-page visual pass (Quick Pass + Full Review)

**Tier → action mapping:**

The checklist below uses Tier 1/2/3 as severity shorthand. They map to action buckets in the Phase 8 report as follows (modulated by declared context from Phase 0):

| Tier | Default action | Client-facing | Internal draft |
|---|---|---|---|
| Tier 1 (ship-blockers) | HOLD | HOLD | HOLD |
| Tier 2 (typography) | FIX IF TIME | FIX IF TIME or HOLD (context-dependent) | NOTE |
| Tier 3 (layout) | NOTE | FIX IF TIME | NOTE |

When in doubt, promote to the higher action bucket. The user can downgrade; a missed HOLD is the failure mode.

**Structured-enumeration approach.**

For each page, issue a single enumeration pass with this structure:

> "List every visual anomaly on this page. For each: location (page N, region in words), category (from the checklist below), action estimate (Hold / Fix-if-time / Note), and a one-line concrete description. Enumerate first, then classify — both within this pass."

This keeps the wide-net behaviour of the old two-pass approach — the cost of noting a non-issue is one line; the cost of missing a real issue is shipping it — without requiring a second inference pass. The "find everything first" discipline is preserved by explicitly separating enumeration from triage within the same output: list all anomalies, then classify them.

**Volume calibration — expected range, not a target:**
- 1–5 pages: typically 6–12 findings
- 5–20 pages: typically 12–20 findings
- 20–50 pages: typically 20–35 findings
- 50+ pages: typically 35+ findings

If you are well below these ranges after completing your pass, do one more careful scan of each page before writing the report. Do not manufacture findings to hit the range — the numbers indicate you may have under-swept, not that you must find more.

For each finding (after second-pass classification):
- Page number, region in words ("bottom-right quadrant", "centre, mid-page")
- What's wrong (concrete, specific — "the phrase 'including GST' is cut off" beats "text is clipped")
- Suggested fix (often more than one valid option — list them, let the user choose)
- Source pointer if mappable (file:line)
- Confidence label (`confident` / `likely` / `possible` — see `references/confidence-rubric.md`)
- Optional: describe the region precisely in words ("bottom-right quadrant, last two lines of body text, between the rule and the footer"). Precise description substitutes for a crop when scripting is unavailable.

HOLD findings deserve the most rigorous evidence. NOTE findings can be a one-line note.

**Locked-content verbatim check.** Some documents declare canonical strings that must appear identically across the artefact and across sibling artefacts (definitions, legal disclaimers, pricing, brand taglines, regulated terms). Indicators that locked content exists: source comments like `<!-- LOCKED -->` / `<!-- DO NOT EDIT -->`, a project README listing canonical phrases, or a memory entry pinning a definition with "verbatim" / "single source of truth". When you spot locked content in scope, the validity sweep must do a verbatim string compare against the canonical version — not just spell-check, not just paraphrase-match. A one-character drift in a locked definition is a HOLD finding because it silently introduces a contradiction with whatever else uses that string. If the canonical source isn't accessible, surface as `possible` HOLD with a request for the user to confirm.

#### Universal Tier 1 — Content integrity (ship-blockers)

These are nearly always `confident` findings. If you see them, they are real.

- **Content clipped at page edge** (bottom, right, anywhere). The page boundary cuts through text, an image, or a UI element. **No exceptions, no "intentional framing" rationalisation.** Any visible text or graphic element that is partially cut off at any page edge is a ship-blocker. Reframing it as a deliberate design choice is the trap; the reader sees a broken page.

**Bottom-edge completion check (mandatory on every fixed-height page).**

For each fixed-height page (any page that uses `height: 210mm` or `overflow: hidden`), perform these explicit checks on the bottom 25% of the page:

1. **Sentence-completion test.** Does the last visible sentence end with terminal punctuation (`.`, `?`, `!`, `:`, or a complete parenthetical)? A sentence ending mid-word, mid-clause, or without punctuation is a HOLD finding. Do NOT rationalise it as a "natural paragraph break" — if there is no period, the content is clipped.

2. **Box/callout border-completion test.** If the bottom visible element is a box, card, callout, or table: does it have a visible bottom border or a clear visual close? A box whose bottom border is missing or runs off the page edge is a HOLD finding. The absence of a bottom border is not a design choice on pages using bordered cards — it is clipping.

3. **Column-completion test.** If the page uses a two-column layout: does the right column contain content? An entirely empty right column on a two-column layout page is a HOLD finding. **Exception scope is narrow:** the exception for "a cover or section opener" applies ONLY when the page uses a structurally single-column layout (no `grid-template-columns: 1fr 1fr` or equivalent). A cover page that uses a two-column grid where one column contains elements at opacity < 0.15 (near-invisible decorative bars, faint motifs) is NOT exempt — those elements are invisible in print and do not constitute "cover design." Flag as Tier 2 on a cover page, Tier 1 on a body page. Do not accept an empty right column as "whitespace breathing room."

4. **Footer-visibility test.** Is the page footer (page number, document title) visible at the page bottom? A missing footer on a body page is a HOLD finding.

5. **Footer content clearance test** (mandatory on every body page with a footer). Does the body content complete cleanly ABOVE the footer zone, or does it appear to be cut off by the footer strip? Check the last 10% of page height for content that ends abruptly (no terminal punctuation, no visual close, sentence trailing off). If content appears to be clipped by the footer zone — text running into the footer area or being hidden behind it — this is a HOLD finding. **Root cause pattern:** `max-height` set to the full page height (e.g. 170mm on an A4 landscape page) without subtracting the footer strip height (~8mm). Content fills to 170mm but the footer occupies the bottom 8mm, silently clipping the last line(s). **Detection:** look at the gap between the last visible content element and the footer rule line. If there is no visible gap (content appears to touch or overlap the footer), it is clipping. **Fix:** reduce `max-height` to leave footer clearance (e.g. 162mm instead of 170mm), or increase `margin-bottom` in the `@page` rule to give the footer margin box more room.

6. **Header content clearance test** (mandatory on every body page with a running header). Is there a visible breathing gap between the bottom of the running header rule line and the first line of body content below it? Content that starts immediately adjacent to the rule makes the page feel cramped and is a **Tier 2 finding (FIX IF TIME)** — promote to HOLD on client-facing documents.

   **The calibration test (ask this explicitly):** Could you slide a finger between the header rule and the first content element and feel space? If the eyebrow or heading appears to be growing directly out of the rule line, it is too tight — regardless of whether the content is technically unclipped.

   **What to look at:** There are two separate text elements near the header rule — one above it (the running header text, e.g. "Section 01 · Introduction · May 2026") and one below it (the first body content, e.g. "SECTION 01 · INTRODUCTION"). The clearance finding is exclusively about the gap BELOW the rule, between the rule and the first body content. The running header text above the rule is expected to sit close to it — that is correct behaviour, not a finding.

   **Root cause and correct fix (Paged.js / pagedjs-cli):** The gap below the rule is NOT controlled by `@page margin-top`. That property sizes the entire top margin box (logo + rule + space above logo). Increasing it adds space above the logo, not below the rule. The correct fix is `padding-top` on the Paged.js content area itself — applied universally so it covers ALL page types including mid-flow continuations.

   **The three failure cases — all require the same fix:**
   - Fixed-height pages (`.page` class with `.page-body` wrapper): the `.page-body` element sits flush at the top of the content area.
   - Flowing section openers (`section-start` without `.page`): the section element's first child sits flush.
   - **Continuation pages of flowing sections** (e.g. `doc-q-section` or `prose-grid` breaking mid-flow): the content fragment that Paged.js places on the new page has no top padding — the element's own `padding-top` was consumed at its opening on the previous page. This is the most commonly missed case.

   **The universal fix (Paged.js):** Apply `padding-top: 6mm` to `.pagedjs_page_content` for all non-cover pages. This operates at the content-area level — whatever fragment Paged.js places there (section opener, continuation paragraph, table row) automatically gets the clearance:
   ```css
   .pagedjs_page:not(:has(.page--cover)) .pagedjs_page_content {
     padding-top: 6mm;
   }
   ```
   With this rule in place, do NOT also set `padding-top` on `.page-body` or `.section-start:not(.page)` — those would double-stack to 12mm.

   **Audit scope:** check header clearance on ALL body pages — not just section openers. Mid-flow continuation pages (pages that begin with a sentence fragment mid-paragraph, or a sub-section heading mid-document) are equally at risk and historically missed because reviewers focus on the start of each section.

   **Do not touch:** `@top-left` / `@top-right` `padding-bottom` — this moves the running header text down inside the margin box (the wrong gap). `@page margin-top` — this moves the logo up/down, not content below the rule.

   **When the universal `.pagedjs_page_content` fix is applied:** the `.page max-height` must account for the added padding. Formula: `max-height = page-height − margin-top − margin-bottom − padding-top`. For A4 landscape with 28mm top margin, 22mm bottom margin, 6mm padding: `max-height = 210 − 28 − 22 − 6 = 154mm`.

   **Upper-bound check — excessive header gap (mandatory on every section opener).** The clearance below the header rule must also not be disproportionately larger than sibling pages. If one page's eyebrow appears to "float" in a large empty zone below the rule while all other section openers have a compact, consistent gap, this is a **Tier 2 (FIX IF TIME)** finding — promote to HOLD on client-facing documents.

   **Detection:** compare the rule-to-eyebrow distance on the flagged page against at least two structural siblings. If the gap is visually ~2× or more than the sibling gap, flag it. Do NOT accept "it's still readable" — excessive gap reads as layout drift and signals a structural error.

   **Root cause (Paged.js):** A flowing `section-start` section (without `.page`) that also contains a `.page-body` child div will accumulate two independent `padding-top` values:
   - `.section-start:not(.page) { padding-top: 6mm }` — on the section container
   - `.page-body { padding-top: 6mm !important }` — on the child wrapper

   This doubles the gap to ~12mm. **The `.page-body` class must not appear inside a flowing `section-start`** — it belongs only inside `.page` (fixed-height) sections. Fix: remove the `.page-body` wrapper div from the flowing section, leaving only the content stack directly inside the `section-start` element.

   **Structural pre-flight (mandatory when HTML source is available):** Before or immediately after Phase 2 rendering, grep the source for this class-mixing anti-pattern:
   ```bash
   # Detect section-start sections (without .page) that contain a .page-body child
   grep -n "section-start\|page-body" index.html | grep -v "page section-start"
   # Look for a .page-body line immediately following a non-fixed section-start line
   ```
   Any `<div class="page-body">` that is a direct child of a `section-start` (without `.page`) is a structural error — it will double the header clearance gap and must be removed.

   **Anti-rationalisation:** "The eyebrow is still legible" is not the same as "there is adequate breathing room." Perform this as a discrete yes/no question on the first body page, then spot-check three more. Do not absorb it into the general visual pass.

7. **Major section opener page-break test** (mandatory on every page that ends with — or begins within the bottom 30% of — a section heading, eyebrow + H1, or numbered section title). Does a major section opener (a new top-level numbered section: "Section 05", "Chapter 3", "Part II", etc.) start on a fresh page? A major section heading appearing in the bottom 30% of any page is a **HOLD finding** — it signals a missing `break-before: page` on the section wrapper.

   **What to look for:** On any page where the last visible element is a heading, eyebrow label, or section title — or where an eyebrow + H1 + lead paragraph group begins below the midpoint of the page — ask: "Is this a new top-level numbered section?" If yes, it should be on a fresh page. The presence of body content before the heading on the same page is the tell: if the page starts mid-content and ends with a heading, the break is missing.

   **The failure mode that hides this:** The review focusses on the *following* page (which appears clean — content starting at the top). The *previous* page, which ends with the orphaned heading, reads as "content then whitespace then heading" — superficially similar to an intended design choice. It is not a design choice. A major section opener at the bottom of a page is always a structural break failure.

   **Root cause (Paged.js / pagedjs-cli):** The section wrapper is using a class like `doc-q-section` or a generic `<section>` with no `break-before: page`. The `doc-q-section` class is designed for Q-level *sub-sections within a running section* — it has `border-top` and `margin-top` but no page break. If it is applied to a *top-level numbered section*, the class is wrong. The `break-before: avoid-page` on `.doc-title` / `.doc-eyebrow` compounds the issue — it tells Paged.js "don't break just before this heading," which pulls the heading down into whatever space remains on the previous page.

   **Fix:** Change the wrapper class from `doc-q-section` (or any non-breaking class) to `section-start`, which has `break-before: page`. Check that any styling provided by `doc-q-section` (border-top, margin-top) is no longer needed once the section gets a fresh page — it usually isn't.

   **Source audit (mandatory when HTML source is available):** After identifying a misplaced section heading visually, grep the HTML for every top-level numbered section (`Section \d\d`, `Chapter`, `Part`, or equivalents). For each, check the wrapper element's class list — it must include `section-start` (or equivalent `break-before: page` class). Any top-level section using `doc-q-section`, plain `<section>`, or a class with no `break-before: page` is a latent bug even if it hasn't yet produced a visible orphan.

   **Anti-rationalisation:** "The heading is still on the page and readable" is not a defence. A major section opener at the bottom of a page destroys the reader's navigation experience — they can't glance at a fresh page to know they're entering a new section. Promote this to HOLD regardless of how readable the heading appears.

   **Continuation-page orphan border check (mandatory on every page that begins mid-flow).** For any continuation page (a page that starts mid-sentence or mid-section rather than at a clean section opener), ask: is there a thin horizontal rule in the top 15mm of the content area, below the header rule gap?

   **CRITICAL: this defect is only ~1–2px thick and sits close to the header. At full-page zoom it reads as a subtle density artefact and is easy to dismiss. You MUST mentally zoom into the top 15mm of every continuation page — look for any horizontal line that is not the header rule itself.**

   If a second thin rule is present: this is a `border-top` from a CSS block element (e.g. `doc-q-section`) repeating on the fragment's continuation page. It is NOT an intentional separator — it reads as a visual glitch.

   **Detection:** A thin rule sitting in the gap between the header rule and the first body text, with no eyebrow/label between the rule and the body text. Structure: [header rule] → [6mm gap] → [orphan rule ← THIS] → [body text]. A legitimate Q-section separator always has the separator above an eyebrow label and heading; an orphan border appears above body text with no label.

   **Why `box-decoration-break: slice` is NOT a reliable fix:** Chromium's print renderer does not honour `box-decoration-break: slice` on fragmented block elements in Paged.js documents. It re-paints `border-top` on every continuation fragment regardless. Do not apply this as a fix — it will appear to work in browser preview but fail in the rendered PDF.

   **Correct fix — use a real DOM element as the separator:** Remove `border-top` and `padding-top` from the CSS of the fragmented element entirely. Replace with a `<hr class="doc-q-separator">` element as the first child of each section that needs a visible separator. Style the `<hr>` with `border-top` and `margin`. Add `break-after: avoid` to keep it glued to the heading that follows. Since `<hr>` is a real DOM node, it only appears where it exists in the source — it cannot duplicate onto continuation pages.

   ```css
   .doc-q-section { margin-top: 0; padding-top: 0; /* no border-top */ }
   .doc-q-separator { border: none; border-top: 1px solid var(--border-subtle); margin: 32px 0 24px 0; break-after: avoid; }
   ```

   Note: the first Q-section in each section (Q1, Open Q1, etc.) does NOT get a `<hr>` — it follows directly from the section opener. Only Q2+ (and equivalent) get separators.

   **Source smell:** any element with both `border-top` and no `break-inside: avoid` in a Paged.js document is a candidate for this bug — Chromium will re-paint the border on every continuation fragment page.

8. **Flowing section footer collision test** (mandatory on every page whose content comes from a `section-start` without `.page`, i.e. a flowing section). Does the last visible element on the page clear the footer rule with visible breathing room? Any element — a heading, eyebrow label, sentence fragment, or Q-section heading — that visually overlaps or sits inside the footer margin band is a **HOLD finding**.

   **This is distinct from the fixed-height footer clearance test (check 5).** Fixed-height pages clip silently via `max-height + overflow: hidden`. Flowing sections have no `max-height` — Paged.js is responsible for the page break. When it fails to break in time, content overruns the footer band visibly: the last element is legible but physically inside the footer strip, overprinting the footer text.

   **The failure mode that hides this:** The content appears "almost on the page" — the heading or label is readable and doesn't look clipped, just close to the bottom. The eye rationalises it as "tight but intentional." It is not. Any body element that sits in the same vertical zone as the footer rule is in the footer margin band — which belongs to Paged.js, not to body content.

   **Detection:** on any page with a flowing section, look at the bottom 8–10% of the page height. Is there a content element (heading, eyebrow, sentence) below the last clear body content gap, sitting immediately above or overlapping the footer text? If yes, it is a footer collision. The tell is seeing the document footer text ("SAFELEDGER · ANALYTICAL DOCUMENT V7 · CONSOLIDATED RECORD") and a body element on the same or adjacent horizontal band.

   **Root cause (Paged.js):** A `section-start` element contains more content than fits on one page, AND the first sibling section has no `break-before: page`. Paged.js flows the sibling's heading into the remaining space at the bottom of the page — which is inside the footer margin band. Two structural fixes exist:
   - **Preferred:** Convert the self-contained intro page to `.page section-start` with `.page-body` wrapper — this gives it `max-height: 154mm` which clips at the right boundary and forces the next section to a fresh page.
   - **Alternative:** Add the `section-start` class to the overflowing section — this is the only reliably honoured `break-before: page` mechanism in Paged.js/Chromium. **Do NOT use inline `style="break-before: page"` or a CSS rule on a non-`section-start` element** — Chromium's print renderer ignores `break-before` on arbitrary block elements that lack the `section-start` class. This has been confirmed in practice: inline style `break-before: page` on a `doc-q-section` was silently ignored; adding `section-start` to the class list worked immediately.

   **Paired finding — sparse following page.** When a flowing section overruns into the footer, the content that was forced to the next page will often produce a sparse page (large bottom whitespace). A page that is notably sparse directly after a footer-collision page is diagnostic confirmation of the overflow, not a separate finding. Surface both together in the report.

   **Source audit (when HTML source is available):** For every `section-start` without `.page` that contains both a heading block AND a `prose-grid` or table: confirm whether the following sibling section has `break-before: page`. If not, the overflow risk is latent — it will produce a footer collision whenever the content fills more than one page. Flag as a latent HOLD even if the current render happens to fit.

These eight checks must be explicitly performed and answered (yes/no) for every body page. Do not treat any of them as optional or implied by the general "content clipped" check — that check has historically been too abstract to catch these specific failure modes.

**Confidence: `confident`** — all eight are binary observable checks. If you cannot determine the answer from the render, increase DPI to 300 and re-render before proceeding.

**Table and list completeness check (mandatory on every fixed-height page containing a table or list).**

For each fixed-height page containing a `<table>`, `<ol>`, or `<ul>`:

1. Count the rows/items in the HTML source for that element.
2. Count the rows/items visible in the PDF render.
3. If the counts differ: this is a **HOLD** finding — "Table has N rows in source but only M visible in PDF; rows [list] are clipped." Do NOT classify this as a density-imbalance finding. It is a content-integrity finding.
4. The fix is always to split the page — never to reduce font size to make more rows fit (that degrades legibility) and never to scale up (that makes clipping worse).

**Confidence: `confident`** — row counts are deterministic. Count the `<tr>` or `<li>` elements in source; count visible rows in the render; compare.

- **Text overrunning its container.** A fixed-width box where content visually escapes the box.
- **Missing or broken images.** Logo not loading, alt text showing instead of an image, broken-image icon.
- **Overlapping elements.** Footer over body. Header over title. Two columns colliding. A modal/badge over content. **Bounding-box overlap test:** when reviewing each page, explicitly ask "do any two text blocks have intersecting bounding boxes? Does any text element overlap with a non-text decorative element (rule line, image, panel fill)?" If yes, Tier 1. Don't rely on global gestalt alone — corner-zone collisions are easy to miss when your eye is reading the centre of the page.
  - **Thin rules and dividers count as overlap.** A 1px-4px horizontal/vertical rule cutting through a line of body text is a Tier 1 finding even though the eye can read past it at fit-to-page. Source smell: a flex/grid container with fixed `top`+`bottom` anchors holding children whose intrinsic content height exceeds the container — children overflow downward and the next sibling's top-border (a card divider, section rule, eyebrow underline) lands on the previous sibling's body text. Symptoms: a rule appears mid-paragraph, or a card "label" eyebrow overprints the previous card's last line. The bounding-box test must include 1px stroke elements, not just filled blocks. Trust this test even when the page "reads OK" overall — if a sectioning rule visibly crosses a glyph, the page is broken.
  - **Rule-through-glyph is a specific check, not a general one.** When a page contains repeating cards/sections separated by rules (top-border accent, hairline, sand-rule eyebrow), perform this explicit per-rule scan: for EACH horizontal rule on the page, does it visually pass through any glyph above OR below it? Not adjacent to — through. Look at the rule's y-coordinate and ask "is there body text the same y?" If you can see character shapes peeking out from behind the rule, that rule is in the wrong place. This check is non-negotiable on any spread that uses card-divider rules.
  - **Source-smell hint that almost always produces this bug:** a CSS pattern like `.cards { position: absolute; top: Npx; bottom: Mpx; display: flex; flex-direction: column; gap: Gpx; }` paired with `.card { border-top: 4px solid; ... }`. The `bottom` anchor caps the available height, but flex children whose intrinsic height exceeds that cap will overflow downward — and each card's top-border lands on the previous card's body text. The fix is to either (a) drop the `bottom` constraint and let the container grow naturally (then position the next sibling/footer based on what's left), (b) shrink card content, or (c) widen the container so cards wrap to fewer lines. Surface this in the report when you see card-stacks with `bottom: Npx` in the source.
- **Corner-zone clipping or collision.** On any landscape spread (1920×1080 or similar), explicitly inspect each of the four corner zones — top-left, top-right, bottom-left, bottom-right — as a separate checklist step. Specifically: is there text in a corner that is being obscured, clipped, or overlapped by an absolutely-positioned element from an adjacent column? Top-right is the most-missed zone because the eye reads left-to-right and tires before reaching it. Multi-column layouts with absolute positioning routinely collide at the inside-corner where columns meet — flag any such collision as Tier 1.
- **Off-page elements.** Anything positioned outside the visible page area.
- **Header/footer collision.** Rule lines, page numbers, or running titles landing on body content.
- **Long-form section continuation pages — missing header or footer (Tier 1).** For any `page--long-form` section that spans multiple PDF pages: every PDF page (not just the first and last) must have a running header (logo + section label) and a running footer (document title + section label). A mid-flow PDF page with no header is Tier 1. A footer appearing mid-page in the flow rather than anchored to the page bottom is Tier 1. **Root cause:** `position: absolute` headers/footers only anchor correctly inside a fixed-height container. When a section has `height: auto` and flows across multiple print pages, the header appears only on the first PDF page and the footer only on the last. **Detection:** in the PDF render, check every continuation page of a long-form section — not just the first page. If the logo/section label is absent from the top, or the footer text is absent from the bottom, this is a Tier 1 finding. **Fix:** the only reliable solution with Chrome/Puppeteer is to split each long-form section into explicit fixed-height `<section class="page">` elements, each with its own `<header class="page-head">` and `<footer class="page-foot">`. `position: fixed` in print mode does not work correctly — Chrome stamps the last fixed element on all pages. CSS `@page` running elements (`element()` function) are not supported in Chrome. **BEYOND VISUAL note:** if the renderer is Chrome/Puppeteer and the document has long-form flowing sections, flag this as a structural infrastructure finding — proper running headers/footers require either section splitting in HTML or switching to a CSS-capable renderer (Prince, WeasyPrint, Paged.js).
- **Long-form body text using narrow single-column width — right margin wasted (Tier 2).** Long-form sections using `max-width: Nch` on body paragraphs leave a dead right margin that reads as whitespace but contains no content. On A4 landscape or portrait documents, single-column text narrower than ~75% of the content area is a Tier 2 density finding. **Detection:** look for a consistent right-side gap of >25% page width in any long-form section. **Fix:** switch to two-column layout using CSS `columns: 2; column-gap: 28px` on the `.page-body`, or use `doc-cols-2` wrapper divs for sections where explicit column control is needed. Note: `columns` CSS does not work with `display: flex` — set `display: block` on the container first.
- **Backgrounds not filling the page.** Cream/navy/branded background failing to reach the edge — paper/white showing through where it shouldn't.
  - **Paged.js / pagedjs-cli specific — content-area-only background (Tier 2, FIX IF TIME).** In Paged.js, each HTML `<section class="page">` element is placed inside `.pagedjs_page_content` — the rectangle between the `@page` margin boxes (header band and footer band). If a page's background colour is applied in CSS to `.page--cover`, `.page--section-break`, or any `section.page` selector, that colour fills only the content-area rectangle. The header and footer margin bands stay white, producing a coloured rectangle floating inside white strips. **Detection:** on any page with a non-white background, look for a colour step at the top and bottom edges of the content area — if the margin bands are a different colour (typically white) from the content body, this is the bug. At low DPI this reads as a subtle warm/cool boundary; at 300 DPI it is clearly a seam. **The failure mode is invisible in browser screen preview** (no Paged.js margin boxes in screen mode) and only appears in the PDF. **Fix:** in `documents-paged.css`, add a rule that targets the full `pagedjs_page` element for pages with special backgrounds — not the `section.page` element inside it. Use Paged.js's `:has()` targeting pattern:
    ```css
    /* Background must fill the whole page — not just the content area */
    .pagedjs_page:has(.page--cover) {
      background: var(--cream-50) !important;
    }
    .pagedjs_page:has(.page--section-break) {
      background: var(--ink-800) !important;
    }
    ```
    This mirrors the existing pattern used to suppress margin-box display on cover pages. Apply the same `background` value that `documents.css` sets on `.page--cover` / `.page--section-break`, so the full page (margin bands included) matches. **Root cause to note in source:** the CSS rule `.page--cover { background: var(--cream-50) }` in `documents.css` is correct for screen/browser preview but incorrect for Paged.js PDF output — it only colours the content area. The Paged.js fix must target the parent `.pagedjs_page` wrapper.
    **Anti-rationalisation:** at thumbnail scale (200 DPI fit-to-page) the seam between content-area cream and margin-band white may appear as a uniform warmth. Always zoom into the top and bottom 10% of any coloured page to confirm the full bleed. If the header rule appears to sit on white while the body below it is cream, the background is content-area-only.
- **Font fallback.** A glyph rendered in a system font (Times, Helvetica, Arial) because the embedded font is missing for that character. Check `metadata.json` font list — if a font you didn't expect is used, surface it.
- **Low-DPI raster assets.** Embedded images under ~150 DPI at print scale — they will look fuzzy. Check `metadata.json` image DPIs.
- **Body or item text below absolute legibility floor — Tier 1 regardless of clipping.** Any body text, numbered-item text, or list content rendered at `font-size` below `10px` is a Tier 1 legibility finding, even if the content is technically present and unclipped. The failure mode: an earlier overflow-fixing pass reduces font size to fit content on the page, the overflow audit passes (no clipping), but the resulting text is unreadable at fit-to-page. Detection: scan all inline `font-size` values on body/item elements — any value below `10px` is an automatic flag. Also check `line-height` below `1.35` on any prose block — tight leading compounds the illegibility. Fix: increase font size to at least `11px` with `line-height: 1.5`, then re-run the clone overflow audit to confirm headroom. If the page genuinely cannot fit the content at legible size, split the page rather than compress the font. **Confidence: `confident`** — font size values are deterministic; sub-10px body text is never acceptable in a distributed document.
- **Body text below the legibility threshold on landscape decks.** On any 1920×1080 (or similar landscape) deck, body text rendering effectively below ~16px at fit-to-page is Tier 1 cramped. Annotation/caption text minimum 13px. Footer / persistent navigation text minimum 13px. The trap: rationalising "it's legible at zoom" — readers don't always zoom, and "fit-to-page" is the typical reading state for projector-aimed decks. If the reader has to lean in or zoom the PDF to read body content, the size is wrong. Pair this finding with a sizing recommendation: bump body, eat any unused bottom whitespace.
- **Figure/diagram too small to read — the "present but illegible" trap.** For every page containing an `<svg>`, `<figure>`, or embedded diagram: ask not just "is it present?" but "are its internal labels readable at the size it renders?" A diagram that passes content-clipping checks (it is not cut off) but whose box labels, annotations, or axis text are illegible at fit-to-page is a **Tier 2** finding (Tier 1 if the diagram is the primary content of the page). The failure mode: a fixed `height` override on an SVG with a wide viewBox squashes the aspect ratio — the diagram renders stamp-sized while the source code appears correct. Detection: zoom into the figure region of the PDF render to 1:1 or 2× and ask "can I read every label?". Source smell: `style="width:100%; height: Npx"` on an SVG with `viewBox="0 0 W H"` where `N/H < 0.25` — the height is less than a quarter of the viewBox ratio, indicating heavy squashing. Fix: increase the explicit `height` value until `height/H ≈ width/W` (natural aspect ratio) or until labels are clearly readable, whichever comes first. Then re-run the overflow clone audit to confirm the enlarged figure still fits the page. **Confidence: `confident`** once zoomed — label illegibility is binary at 2× zoom.
- **Tabular / structured-list inconsistency.** Where a page contains a multi-row data layout (a table, an objection grid, an anti-pattern list, any structure with repeating rows), every row must share the same treatment: equal vertical padding, same horizontal-rule treatment (every separator present, OR none — never mixed), consistent baseline rhythm. Symptoms to watch for: some rows have a top border and others don't; gaps between rows visibly differ; one row is taller than its neighbours for no content reason; the rule colour or weight changes between rows. Inconsistent row treatment is a structural Tier 1 finding because it makes the table read as broken or half-edited. **Confident** — row-level consistency is mechanically verifiable.
- **Step / page / count indicators that don't match the actual document.** "Step 1 of 4" on a doc that's been re-paginated to 5 pages; "Page 7 of 10" when the doc has 12 pages; "Section 3 of 4" sitting on the fifth section. The reader trusts these counts as ground truth — a mismatch is a factual error visible to the reader. Check every X-of-Y pattern against the rendered count. **Confident** — counts are deterministic.

**Anti-rationalisation rule for bottom-edge findings.** The most common failure mode in visual review of fixed-height pages is rationalising a clipped bottom as intentional:

- "The content ends naturally near the bottom" — check for terminal punctuation. If absent, it's clipped.
- "The whitespace is breathing room" — check whether a column is entirely missing. If so, it's clipped.  
- "The box design doesn't need a bottom border" — check whether sibling boxes on the same page have bottom borders. If they do, this one is clipped.
- "The page looks clean" — this is the trap. A clipped page looks clean. That's the problem.

When in doubt, promote to HOLD. The user can downgrade; a shipped broken page cannot be unshipped.

#### Universal Tier 2 — Typographic problems

Mostly `likely` — judgment is involved on what counts as awkward.

- **Awkward line breaks that break meaning.** "AUD ex-" / "GST". A name split across lines. Numbers separated from their units.
- **Single-word last lines (orphans/widows).** A single word alone on the final line of a paragraph.
- **Mid-word hyphenation at column edges**, especially in display type (headings, callouts).
- **Awkward column splits in two-column lists.** Item title in column A, description in column B.
- **Stretched or shrunk text** that doesn't match its style elsewhere — letter-spacing or font-stretch nudged.
- **Heading hierarchy violations.** H2 looking bigger than H1, eyebrow bigger than body.
- **Multiple logical units crammed into one paragraph block — the "bold heading mid-paragraph" smell.** When a page uses `<strong>` or bold text to introduce a new named concept mid-paragraph (e.g. "…end of Layer 1. **Layer 2 — Decision Support.** Signals surface to…"), this is a structural Tier 2 finding. The reader must visually parse the bold label as a section break — there is no whitespace or block separation to help them. The detection test: scan every `<p>` block for two or more `<strong>` or `<b>` elements that each introduce a distinct named item (Layer N, Module N, Step N, Finding N). If found, each named item should be its own `<p>` element in a `doc-stack` container, not a bold span mid-paragraph. **Source smell:** `<p>...<strong>Layer 1</strong>...body...<strong>Layer 2</strong>...body...</p>` — one `<p>` containing two or more conceptually distinct bold-labelled sections. **Fix:** split into separate `<p>` elements wrapped in a `doc-stack-3` or `doc-stack-4` div so paragraph spacing provides the visual separation. Re-run the overflow clone audit after splitting — the added spacing will consume headroom. **Confidence: `confident`** — bold-label counting in source is deterministic; the visual impact is immediately legible at 1:1 zoom.

#### Universal Tier 2 — Form & interactive-element semantics

Applies to any fillable document (field sheets, survey forms, response cards, intake forms). Mostly `likely` to `confident` — these are visual symptoms with clear structural causes.

- **Doubled checkbox containers.** A pill, chip, or bordered button that already reads as a tickable surface AND contains an inner drawn checkbox glyph. Symptoms: a small empty square inside a larger bordered shape; "two boxes" where the user expects one. Source smell: a `.pill` / `.chip` / `.button` class with its own `border` rendering a child `.checkbox` / `.box` / `.tick` element. Fix: drop the inner checkbox so the outer container is the checkbox, OR strip the outer border so only the inner box reads as tickable. Don't keep both. **Confident** if the source confirms the nesting; otherwise `likely`.
- **Inconsistent checkbox alignment.** The same logical "checkbox + label" row renders with the box at different baselines across the document (some sit on the baseline, some float mid-cap-height, some sit below the descender). Usually caused by mixing `vertical-align`, `align-items: center` and `align-items: baseline` across sibling components. Pick one alignment policy and apply it everywhere. **Survivor check:** even after a global fix, individual rows often retain the issue because a parent container has its own `align-items` declaration that overrides. Walk EVERY row containing a checkbox after the fix is applied — don't trust that a top-level CSS change reached every leaf. The "I changed `.box-chk` so it's all fixed now" claim is the trap. Each per-row class (`.close-row`, `.traction-row`, `.ask-row`, `.lb-tier-row`, `.cur-pill`, `.path-chip`, etc.) has to be checked individually.
- **Inconsistent checkbox sizes.** Multiple distinct box sizes within one form when a single size would do. A small variant *can* be intentional (mini-tick in a category strip) but should be a deliberate exception, not drift.
- **Checkbox-shaped label bullets.** Headings, eyebrow labels, or list bullets accidentally rendered as a square outline - reads as a tickable field that isn't. Especially common when a square character (`▢`, `□`) is used as a bullet mark.
- **Form fields without underlines.** A label like `Name:` followed by trailing whitespace where the user is expected to write - but no rule line. Either add the rule or make it clear the field is meta (auto-filled, n/a). The reverse (a rule line with no label) is also a finding.
- **Rule lines that don't fit a person's handwriting.** Inline form fields shorter than ~25mm of writable space when a name or date is expected. A rendered field that is technically present but visually too short to use is a Tier 2 finding.
- **Radio buttons rendered as squares (or vice versa).** A field that allows only one selection should use a circle; a field that allows multiple should use a square. Mixing the two confuses experienced form-fillers. Surface as a `likely` finding since the convention isn't universal but is widely held.
- **Sub-options nested under a tickable parent without a visual indent or branch line.** Looks like a flat list of equal-status options when the structure is hierarchical.
- **Field-to-label visual misalignment.** A label and its field don't share a baseline or grid line — `$` sign sitting on the baseline next to an underline at a different y, label rendered in display font next to a body-font field with their cap-heights fighting, label column right-aligned but field column left-aligned with no shared anchor. Different from checkbox alignment — this is about every kind of form field (rules, dollar fields, dropdowns, signature lines). Source smell: a flex row mixing `font-family` declarations with no `align-items` set. Pick one alignment policy per row type and apply it everywhere.
- **Inline hint placement drift.** The same kind of inline hint (form-fill instruction, scope qualifier, "tick one" reminder) appears in different positions across the document — sometimes beside the eyebrow, sometimes under the label, sometimes on the same row as the field. Each position works individually; mixed positions create a "where do I look?" feeling. Pick one canonical position for each hint role and apply globally.
- **Wrap-fragility in chip / pill / tag rows.** A flex row containing fixed-width chips that has `flex-wrap: wrap` set on the parent but no `min-width: 0` or `flex-shrink` policy on the chips. Renders fine at the design width; under any narrowing (long labels, translation, smaller column) the chips stay on one line and overflow rather than wrapping. Stress-test by checking whether any chip touches or escapes the right edge of its parent. `likely` if the render shows the chip near the edge; `confident` if escaping.

These are *form-aware* checks - they only apply where the document is a fillable artefact (field sheet, response form, intake card, scoring sheet, survey). Skip them on prose documents.

#### Universal Tier 2 — Background and contrast legibility

Different from accessibility / WCAG checks (out of scope per the skill's stated boundaries). This is *design-system misuse* — a brand swatch applied at full saturation when the system also offers a tint variant for that purpose, or a hairline rule using an alpha colour that disappears on certain backgrounds.

- **Brand swatch at full saturation used as a panel fill.** A mid-tone brand colour (browns, sands, mossy greens, terracottas — any swatch dark enough that white-bordered controls or sub-headings stop reading cleanly) used as a >40mm-wide panel background when the design system offers a 30-50% tint of the same swatch. Symptom: text technically legible but visually muddy; small UI elements (checkboxes, hairlines, eyebrow rules) lose definition; the panel feels heavier than its content warrants. Source smell: `background: var(--brand-mid-tone)` on a panel class, when the same CSS file declares `--brand-mid-tone-50` or `--brand-mid-tone-30`. Fix: swap to the tint variant; reserve the full swatch for small accents (chip borders, eyebrow underlines, badge fills). `likely` to `confident` depending on the swatch.
- **Hairline rules that disappear on tinted backgrounds.** A rule line declared with an alpha colour (e.g. `rgba(27,99,52,0.4)`) reads cleanly on white panels but becomes invisible on tinted brand-coloured panels because the alpha mixes with the tint instead of the white. Symptom in render: eyebrow underline visible on some panels, invisible on others. Fix: use the solid colour at a lower opacity-baked-in form (or just `var(--brand)` solid) so the visibility doesn't depend on what's underneath.
- **Foreground / background contrast pairs that work on screen but not in print or photocopy.** Sand-on-cream, sky-blue-on-white, light-grey-on-paper. Screen rendering smooths the difference; matte print loses it; monochrome photocopy washes it out entirely. Surface as `possible` if the artefact is print-bound; check the doc's intended use case before flagging.
- **Low-saturation eyebrow / overline labels on tinted boxes.** Faded eyebrows in pale grey or alpha-forest reading fine on white but vanishing on a Sand or Sun-tinted callout. Same root cause as hairline-rule disappearance — alpha colours mix with the panel tint.
- **Same brand swatch used at multiple opacities within one document, inconsistently.** Sand at 100% on one panel, Sand-50 on another, with no design-system rule explaining why. Pick one rule (e.g. "100% for accent borders, 50% for panel fills") and apply consistently. Tier 3 if visually fine, Tier 2 if the inconsistency reads as drift.

These checks apply to any branded artefact, not only forms. They overlap with brand-guidelines audits but are scoped here to the legibility outcome (can the reader read the thing?), not the brand-rule outcome (does the swatch usage match the style guide?).

#### Universal Tier 2 — Density imbalance across pages

Cramping and whitespace-pooling are usually *paired*: one page is bunched against the top while another (or the same one's bottom half) has 20-30mm of unused vertical space. Looking at any single page in isolation, neither is obviously wrong — the cramped page "fits its content," the spacious page "has natural breathing." The finding only surfaces when you compare pages.

**This is the kind of issue a tired human reviewer will miss and the skill is supposed to catch.** Don't accept "the page fits" as a non-finding when sibling pages are loose. Don't accept "the page has whitespace" as a non-finding when sibling pages are jammed. The asymmetry IS the finding.

Operational rule:

1. For each page, measure (or eyeball) the bottom dead-whitespace gap — the space between the last content element and the footer rule.
2. Compute the median across all body pages (skip title slides, section dividers, single-column pages with structurally different content).
3. **Flag any page whose bottom gap is more than ~2× the median as `excessive whitespace` — Tier 2.** Pair it with the page(s) below the median.
4. **Flag any page whose bottom gap is less than half the median as `cramping` — Tier 2.** This is the inverse finding and matters even more, because cramped pages tire the reader.
5. Surface BOTH directions in the report. The fix is usually "redistribute content from cramped pages into spacious ones" or "increase row spacing on cramped pages until the bottom gaps even out."

**Sparse page diagnosis — falsely sparse vs genuinely sparse (critical distinction).**

Before treating a sparse page as "needs more content or larger text," diagnose WHY it appears sparse:

**Step 1 — Count source rows vs visible rows for any table or list.**
If the page contains a table or numbered list, count the rows/items in the HTML source and compare to the rows/items visible in the PDF render. If the counts differ, the page is **falsely sparse** — content is there but clipped by `overflow: hidden`. Scaling up font/padding will make clipping worse. The correct fix is to **split the page**.

**Step 2 — Apply the Playwright overflow check.**
Run `scrollHeight > clientHeight` on the page element. Any positive overflow confirms falsely sparse — do not scale up.

**Step 3 — Only scale up if genuinely sparse.**
If source row count matches visible row count AND overflow check is zero: the page is genuinely sparse. Scaling up font sizes, increasing row padding, or increasing stack gaps is the correct fix.

**Decision tree:**
```
Sparse page detected
    ↓
Count source rows vs visible rows in PDF
    ↓
Counts differ? → FALSELY SPARSE → Split page (add continuation page)
    ↓
Counts match? → Run scrollHeight > clientHeight
    ↓
Overflow > 0? → FALSELY SPARSE → Split page
    ↓
Overflow = 0? → GENUINELY SPARSE → Scale up font/padding/gaps
```

**Never scale up on a falsely-sparse page.** This is the most common mistake: the page looks sparse, you increase font size, the visible rows look better, but more rows are now hidden below the clip boundary. The page still clips — it just clips at a different row. The reader still loses content.

This finding is **always actionable**, even when the skill itself can't apply the fix (CSS is the user's). When you can't apply the fix, **say so loudly** — don't bury it. The user reading the report should leave knowing "page 2 is cramped, page 1 has room to give, here's what to redistribute."

Do NOT downgrade this to Tier 3 just because no single page looks broken. The whole-document feeling of "rushed in places, sparse in others" is exactly the visual-quality outcome the skill exists to flag.

**Whitespace + smallness pairing — promote to Tier 1.** When a page has BOTH significant unused whitespace at the bottom (>20% of canvas height empty) AND body text that feels small (below the legibility threshold or below sibling-page body sizes), this combination is a Tier 1 sizing finding. The fix is unambiguous: enlarge the body text to fill the space. Do not propose adding more content as the fix, and do not flag the whitespace and the smallness as two separate Tier 2 findings — they are one Tier 1 issue with one obvious resolution.

#### Universal Tier 3 — Layout & rhythm

Mostly `likely` or `possible`. Compare against sibling pages.

- **Misaligned baselines across columns** — left-column body text not lining up with right-column body text where they should.
- **Inconsistent margins between similar pages** — one page's body starts at a different y than the next.
- **Uneven gaps between repeating elements** — three timeline weeks not equal-width, profile cards not symmetric.
- **Floating content** — pinned high with too much whitespace below it for no reason.
- **Excessive whitespace** — page feels half-empty *compared to its siblings*.
- **Cramped whitespace** — elements jammed against each other *compared to its siblings*.
- **Rule lines** at inconsistent widths or positions across pages.
- **Footer/page-number alignment** drift across pages.
- **Logo size or position drift** between pages.
- **Header-to-body gap inconsistency across pages.** If the clearance between the running header and first body content visibly differs between pages — tighter on some pages, more open on others — flag as a layout-rhythm finding. Source smell: pages that use different first content elements (an eyebrow label vs a section heading vs a paragraph) with different top margins, while the header has a fixed height. Fix: standardise the top-of-body margin on all page content containers, not on the individual elements.
- **Heading-structure internal spacing drift across sibling pages.** When two or more pages share the same structural template (eyebrow → H1 → intro paragraph, or eyebrow → H1 → lead → body), the vertical gaps between those elements must be visually consistent. If one page's eyebrow-to-H1 gap or H1-to-intro gap looks tighter or looser than its siblings, this is a **Tier 2** finding — the page reads as lower production quality even when no content is clipped. **Detection:** identify a group of sibling pages (same section, same layout template) and compare the vertical rhythm in the top 20% of each page. A gap that is noticeably smaller on one page but not others is the finding. **Source smell:** the outer flex stack uses a different `doc-stack-N` class (different gap value) than sibling pages — e.g. `doc-stack-3` (12px gap) on one page vs `doc-stack-4` (16px gap) on all others. The fix is always to match the class to the sibling. **This is a cross-page comparison finding — it cannot be caught by inspecting a page in isolation.** You must explicitly compare each page's top-block spacing against at least two sibling pages before declaring it consistent.

#### Cover / title page checks (P1/P2)

Apply these checks whenever page 1 is a cover or title page. They are scoped to page 1 (or whichever page carries the cover treatment) and do not apply to body pages.

- **Cross-page background consistency** (P1 — `likely` to `confident`)
  Does page 1 (cover/title) have a noticeably different background colour from body pages? If yes, flag it — it may be intentional (full-bleed cover treatment) or a bug (`page--cover` CSS class applying a different colour token). Check the HTML for a `.page--cover` class and confirm whether the colour difference is by design. If no `.page--cover` class or explicit design note explains the difference, treat as a `likely` FIX-IF-TIME finding and surface it for the user to confirm. Source smell: a generic `.page` background token accidentally applying to the cover when the body uses a different token (or vice versa).

- **Cover page content utilisation** (P1 — `likely`)
  On the cover/title page, does the right half (or any large zone) of the page appear largely empty or contain only faint decorative elements (opacity < 10%, or a near-invisible motif)? A cover page should use its full width meaningfully — either extend content across the full width, or carry a designed visual element (illustration, data motif, branded graphic) that fills the space intentionally. **Flag any cover where more than 40% of the page area is blank or sub-10%-opacity decorative content.** This is not the same as "breathing room" — a body page with modest margins is fine; a cover with a half-page blank zone reads as unfinished. Suggested fixes: extend typography or tagline across the full width; add a designed full-bleed image or motif to the empty zone; or adopt a full-width single-column layout instead of splitting the cover into columns.

- **Cover page grid vs full-width treatment** (P2 — `possible`)
  Does the cover page use the same two-column `doc-cols-rail` or `1fr 1fr` grid as body pages? Cover/title pages should typically break from body layout conventions and use full-width composition. A cover constrained to a body grid layout often looks like a body page with a large title — not a designed cover. Flag if the cover is using the standard body column grid with no override. This is a `possible` finding (not every project will want a full-bleed cover), but it should be surfaced so the user can confirm the grid was a deliberate choice rather than an inherited default.

---

**Quick Pass exits here.** Proceed directly to Phase 8 (action-first report).

Full Review continues to Phase 4 (cross-page consistency).

---

### Phase 4 — Cross-page consistency pass (Full Review only)

Where Phase 3 looks at one page at a time, this phase compares pages to each other. This is where you outperform a human reviewer — humans can't easily compare slide 3 and slide 17 from memory.

Measurements to collect across all pages and surface as drift if they vary unexpectedly:
- Logo bounding box (x, y, width, height)
- Footer y-coordinate and height
- Body text size (sample one paragraph per page)
- Margin starts (left, right, top of body)
- Eyebrow style presence/absence
- Rule line colour, width, position
- **Heading block internal gap rhythm.** For every page using an eyebrow → H1 → intro/lead structure, compare the visual gap between (a) eyebrow and H1, and (b) H1 and intro paragraph, against at least two sibling pages with the same structure. A page whose gaps are noticeably tighter or looser is a Tier 2 finding. Source: check the `doc-stack-N` class on the outer wrapper div — `N` encodes the gap (stack-3 = 12px, stack-4 = 16px, stack-5 = 20px). All sibling pages should use the same N. **This check must be done as a batch comparison across the group, not page-by-page in isolation.**

- **Header-clearance gap calibration across section openers (upper and lower bound).** For every section opener page, compare the visual distance between the header rule and the first body element (eyebrow or heading) against at least two structural siblings. Both bounds matter: (a) lower — gap must exist (not flush), and (b) upper — gap must not be disproportionately larger than siblings (~2× or more). A page that looks "floaty" compared to its siblings has an excessive gap — flag as Tier 2. **Source smell:** a flowing `section-start` (without `.page`) containing a `.page-body` child — this causes padding-top to double-accumulate (section container + page-body wrapper). The batch comparison is mandatory; the excessive-gap pattern is only visible relative to siblings, not in isolation.

Use `references/confidence-rubric.md` to decide whether drift is "intentional variation" or "accidental drift." If a page is structurally different (title slide, section divider), don't flag it for not matching body pages.

### Phase 5 — Type-specific pass (Full Review only)

Load the appropriate reference based on what you identified in Phase 1:
- Slide deck → `references/slides.md`
- Book/manuscript → `references/books.md`
- Multi-page report or proposal → `references/reports.md`

Each contains type-specific Tier 1-3 checks not universal enough for the main checklist (bleed/safe area for print, TOC accuracy for reports, etc.).

### Phase 6 — Diff against reference (Full Review only)

If the user supplied a previous version, brand template, or other reference document, Read both sets of rendered PNGs (new vs reference) using the Read tool and describe differences per page. Surface pages with significant drift. Do not flag the diff itself as a finding unless drift is unexpected — sometimes the user is intentionally iterating.

### Phase 7 — Mechanical fixes (Full Review only)

**Why Phase 7 (not Phase 3):** Mechanical fixes run AFTER the visual pass so the original render is available as a baseline. If a fix introduces a regression (em-dash substitution breaks a ligature, quote normalisation corrupts a code sample), the Phase 2 render is still in context for comparison.

**Gates:**
- Source must be editable (Phase 0 check). If not editable, skip entirely.
- Full Review mode only. Quick Pass skips Phase 7.
- User consent required: before applying any change, present the list of proposed modifications and wait for approval. Do not apply changes silently.

After applying fixes, re-render using the Phase 2 commands. Note any new findings introduced by the fixes and include them in the Phase 8 report tagged `[introduced by mechanical fix]`.

---

Read `references/house-rules.md`. Apply find-and-replace style fixes to the **source** (not the render):

- Em-dashes (—) and en-dashes (–) → spaced hyphen ( - ) per house rule
- Trailing periods on `<li>` items → removed
- Smart quote normalisation per house rule
- Other rules listed in house-rules.md

Apply find-and-replace changes using the Edit tool on the source file. Log every change in a `mechanical_fixes.log` file in the same directory as the source, format: `[timestamp] file:line | before → after`. Then **re-render** so subsequent phases see the fixed version.

If no source is available, skip this phase. Note it in the report.

### Phase 8 — Action-first report (Quick Pass + Full Review)

Structure the report around what the user needs to do, not what category the finding falls into. Three action buckets replace the old Tier 1/2/3 taxonomy.

**Report header (mandatory):**

```
# Visual Review — <document name>

**Rendered:** <timestamp>, <page count> pages
**Render method:** [pdftoppm 300 DPI | Playwright/Chromium | text-only (non-visual)]
**Mode:** [Quick Pass | Full Review]
**Source:** [editable at <path> | read-only | not provided]
**Context declared:** [Client-facing | Internal draft | Print production | not declared]
**Mechanical fixes applied:** [<count> (see log) | none | skipped — source not editable]
```

If render method is text-only, insert immediately after the header:
```
> ⚠ TEXT-ONLY PASS — visual issues not assessed. Content issues only.
```

**HOLD — fix before sending**

Findings that would cause a recipient to reject or return the document, or that would embarrass the sender if shipped.

Context modulation (declared in Phase 0):
- *Client-facing*: tabular inconsistency, count mismatches, pricing ambiguity, versioning mismatch → HOLD
- *Internal draft*: same findings → FIX IF TIME (lower bar)
- *Print production*: font not embedded, low-DPI raster → HOLD
- *Client-facing (screen PDF)*: font not embedded → FIX IF TIME

Each finding:
```
### HOLD — <one-line summary>
- Page: N, Region: <description in words>
- Confidence: confident | likely | possible
- What's wrong: <concrete, specific — "the phrase 'including GST' is cut off at the right edge">
- Suggested fix: <list options; designer chooses>
- Source pointer: <file:line if available>
```

**FIX IF TIME — reduces quality but not a blocker**

Findings a careful reviewer would fix before delivery but that would not cause rejection. Roughly: typography, density imbalance, visual inconsistency.

Same finding format as HOLD.

**NOTE FOR NEXT VERSION — valid, but out of scope for this delivery**

Polish items, layout rhythm, possible findings the user may want to log but not fix now.

**TYPE-SPECIFIC CHECKS (Full Review only)**

Findings from the slides/books/reports type-specific pass. Include slide-specific Tier 4 brand checks here as well.

**CROSS-PAGE DRIFT (Full Review only)**

Measurements that vary unexpectedly across pages: logo bounding box, footer y-coordinate, body text size, margin start, eyebrow presence.

```
### Drift — <item>
Pages affected: N, M, O
Expected: <value from majority of pages>
Observed: <variant value>
Likely cause: <accidental | intentional design — verify>
```

**BEYOND VISUAL (all modes)**

Non-visual issues noticed during review. Clearly labelled as out of visual scope.

- *Content issues*: TOC mismatch, cross-reference broken, factual disagreement, canonical-string drift
- *Structural issues*: heading hierarchy skip, metadata (Title/Author fields)
- *Editorial notes*: confusing phrasing flagged but not rewritten

**SUPPRESSED FINDINGS (all modes)**

If a `.visualreviewignore` file is present, every suppressed finding MUST appear here. Never suppress silently.

```
[suppressed] page:N <finding-type> — rule: "<exact rule text>"
[stale rule] page:N <finding-type> — no matching finding in this review; rule may be outdated
```

**MECHANICAL FIXES APPLIED (Full Review only, if any)**

Every change: `file:line | before → after`

---

End the report with:

> Want to act on any of these? Reply with finding IDs (e.g. "HOLD-1, FIX-3") or "export fix-guidance" to receive the Phase 9 fix-guidance list. Re-review requires a fresh invocation of this skill on the updated source.

### Phase 9 — Fix-guidance export (Quick Pass + Full Review)

The fix loop is not a skill feature — it is a multi-session workflow. This phase outputs a structured fix list for the user or a separate edit agent to consume. Re-review requires a fresh invocation of this skill on the updated source.

**Why the in-session loop is unreliable:**
1. Accumulated context across iterations biases re-review — findings that were "resolved" may simply scroll out of context
2. Re-renders are not guaranteed idempotent within a session (font rasterisation, anti-aliasing, and Playwright/pdftoppm minor version differences can shift pixel positions)
3. Cascade effects from fix N affect what fix N+1 sees, in ways the user cannot audit from inside the session

A fresh invocation on updated source is the correct pattern.

**Fix-guidance output format:**

For each HOLD and FIX-IF-TIME finding, output one entry:

```
ID: <finding-id e.g. HOLD-1>
Page: <N>
Region: <description>
Action: <one-line fix instruction>
Options:
  A. <option A>
  B. <option B>
Source: <file:line if available>
Confidence: <confident | likely | possible>
```

Collect all entries under a `## Fix-guidance export` section at the end of the report.

**What Phase 9 is NOT:**
- It does not apply any fixes (except Phase 7 mechanical fixes, which are separate and user-approved)
- It does not re-render within this session
- It does not verify that a fix resolved a finding

To re-review after applying fixes: update the source, then invoke `/visual-review` again. Each invocation is independent.

## Confidence labels — when to use which

Full rubric with examples: `references/confidence-rubric.md`. Inline summary:

**`confident`** — provable from the render. A reasonable person looking at the same crop would agree without further context. Binary, observable in pixels. Examples: clipped text (letters running off page edge), broken-image icon, white gap where a brand background should reach edge, font fallback confirmed by pdffonts metadata. If you write `confident` and the user disagrees, your calibration is off — default down a level.

**`likely`** — strong visual signal, but whether it's a problem depends on context the user has and you don't. Visual signal is clear; design intent is ambiguous. Examples: a single word alone on the last line (orphan — could be intentional emphasis, usually isn't), footer y-coordinate 3mm higher than all other pages (likely drift, could be intentional for this page's structure), profile cards at slightly different widths (likely accidental, could be intentional emphasis).

**`possible`** — flagging for awareness, not asserting a problem. Signal is weak, subjective, or you'd want a second opinion before calling it. Examples: "page 8 feels half-empty compared to its siblings," "faint horizontal line across mid-page — possibly a render artefact," "ratio between eyebrow and body type feels tighter than on other pages."

`possible` findings are easy to dismiss on a fast skim — that's the point. If you find yourself labelling many findings `possible`, consider whether you're seeing real signal or pattern-matching the checklist.

Confidence is not severity. A `possible` HOLD finding still belongs in HOLD. The label tells the user how hard to look before acting.

## What to ignore

Be sparing about what you suppress. The defaults here are *narrow* — when in doubt, surface and let the user dismiss.

- Aesthetic preferences with no rule violation ("I would have used more blue" is not a finding).
- Findings already documented in a `.visualreviewignore` file (see below).

For things like "intentional-looking design choices" — section dividers with different layout, title slides without footers — *flag them as `possible`* with a note like "may be intentional design — verify." Don't silently drop. The user can dismiss in two seconds; the alternative is missing the case where it actually IS broken.

## .visualreviewignore — the escape hatch

If a project has a `.visualreviewignore` file at its root, read it and skip any matching findings. Format is one rule per line:

```
# Title slides have intentionally different layout
page:1 layout-drift

# Section dividers don't have footers
page:5,9,13 missing-footer

# The pricing callout intentionally extends past the column
page:* class:pricing-callout overflow
```

This file is yours (the user's), version-controlled, and authoritative. Trust it. If the user keeps flagging the same false positive, suggest they add a rule to `.visualreviewignore`.

**Mandatory reporting.** Every suppressed finding MUST appear in the SUPPRESSED FINDINGS section of the Phase 8 report. Never suppress silently. Format:

```
[suppressed] page:N <finding-type> — rule: "<exact rule text from .visualreviewignore>"
```

**Stale rule detection.** At the end of every review, check each ignore rule against the candidate-findings list. If a rule matched no finding, note it:

```
[stale rule] page:N <finding-type> — no matching finding in this review. The underlying issue may have been fixed; remove this rule if no longer needed.
```

**Valid finding-type values for .visualreviewignore:**

| Type | Meaning |
|---|---|
| `layout-drift` | Margin, position, or spacing inconsistency |
| `missing-footer` | No footer on a page where one is expected |
| `missing-eyebrow` | No eyebrow on a body slide |
| `overflow` | Content escaping its container |
| `orphan` | Single word on last line of paragraph |
| `density-imbalance` | Whitespace or cramping relative to sibling pages |
| `brand-drift` | Colour or logo not matching brand reference |
| `rule-overlap` | A divider rule intersecting body text |
| `text-inferred` | Suppress a text-only finding (use when you know the visual version is correct) |

Unknown types are currently ignored silently. Use the closest matching type from the table.

## Reasoning from PDF metadata

The `pdfinfo` and `pdffonts` output is more than a sidecar — *infer* from each flag:

| Metadata flag | What it implies | Action |
|---|---|---|
| Font emb: no | The document will fall back to a substitute on any machine without that font installed. Spacing breaks, layout shifts, columns can overflow. | HOLD if any text-bearing font; ship-blocker for distribution. |
| Tagged: no | No semantic structure for screen readers / assistive tech. | NOTE (note for awareness; out of scope as a fix-it but worth surfacing). |
| Optimized: no | PDF not linearised — slow first-paint in browser viewers. | NOTE for distribution-by-link docs. |
| Title: untitled / Author: anonymous | Document Properties shows placeholder values to anyone who opens them. | HOLD for client-facing; FIX IF TIME otherwise. |
| Custom Producer (e.g. "ReportLab", "WeasyPrint") | Hints at known footguns: ReportLab's "Page X of N" requires a two-pass build (often broken at "Page X of 1"); WeasyPrint can leak default fonts (Times New Roman) when CSS font-family is unset. | Investigate and verify. |
| Page size matches trim exactly (no bleed) | Full-bleed art will be cropped to white edges in print. | HOLD if print-bound. |
| File size unusually small for page count | Possible silent content drop (missing images). | FIX IF TIME worth checking. |
| Multiple producers in metadata | Composite PDF — pages may have inconsistent rendering. | Investigate. |

**The point: every metadata flag is a hypothesis to check against the visual evidence.** Don't just dump the metadata into the report — reason from it.

## Working principles

**Look at every page.** Don't sample. The point of an automated reviewer is consistency the human can't match. A skipped page is the page with the bug.

**Describe what you see, not what you assume.** "The footer rule on page 7 appears to overlap the bottom line of body text" beats "the footer on page 7 is broken." Specificity is trust.

**Crop your findings.** Words describing a region are slow to triage. A cropped image of the offending region is fast. Always save crops; reference them in findings.

**Defer judgment to the user.** You suggest fixes. They decide. Even on HOLD findings — clipping has multiple valid fixes and the user knows the design constraints you don't.

**When you can't fix it, surface it loudly.** Some findings the skill can describe but not auto-fix (cramping/density imbalance, intentional design choices that nonetheless feel off, ambiguous structural decisions). The mistake is to either fix it badly or stay silent. The right move is to put it in the FIX IF TIME section with the words "I'm flagging this — fix not applied because it requires a judgement call only you can make" and explain what's wrong and what the options are. The user's job is the judgement; your job is to make sure they get to make it.

**Re-render after every fix.** Non-negotiable. Pagination is fragile.

**HOLD findings first. Always.** A reader of your report should be able to stop after HOLD and know whether the doc can ship.

## When to bail

Stop and ask the user if:

- The PDF won't render (corrupt, password-protected, unusual format).
- The doc type is genuinely unclear and the type-specific check matters (e.g. is this a one-off slide or page 1 of a deck?).
- A "fix" you're about to apply might be wrong (e.g. a finding marked `possible` HOLD — let the user confirm before editing source).
- Cascade effects in the fix loop produce more new findings than they resolve. Something is structurally wrong; stop iterating and report.

## Files in this skill

- `references/slides.md` — slide-deck type-specific checks
- `references/books.md` — book/manuscript type-specific checks (KDP, print, bleed/safe area)
- `references/reports.md` — multi-page report/proposal type-specific checks
- `references/house-rules.md` — Daniel's style rules (em-dashes, bullet periods, capitalisation, date formats, locked content)
- `references/confidence-rubric.md` — full confidence labelling guide with examples

Note: a `scripts/` directory is referenced in older versions of this skill but does not exist. The script references have been replaced with inline bash commands (Phase 2) and prose descriptions. If scripting is needed in future, the `evals/` directory structure exists as a starting point.
