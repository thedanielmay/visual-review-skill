# Paged.js / Chrome renderer specifics

**Load policy:** Read this file at Phase 0 for any PDF or HTML input. The content is
additive — Paged.js checks supplement the universal checks in SKILL.md Phase 3. Apply
PJ-checks only when Paged.js signals are present; skip them for Word exports, InDesign
PDFs, or other renderers.

**Paged.js detection signals (check at Phase 0/Phase 2):**
- HTML source contains `.pagedjs_page` class or imports `paged.polyfill.js`
- `pdfinfo` metadata shows `Producer: pagedjs-cli` or `Producer: Paged.js`

If none of these signals are present after Phase 2 metadata collection, skip all PJ-N
checks and note in the report header: `Renderer: non-Paged.js — PJ checks skipped`.

**Structure:** Each PJ check opens with its visual trigger symptom (what you see in the
PDF), then the root cause, then the fix. Read by symptom, not by number.

---

## Renderer-specific background: what Paged.js does

Paged.js is a JavaScript polyfill that implements CSS Paged Media (W3C spec) in Chromium.
It wraps each HTML `<section class="page">` in a `.pagedjs_page` container with separate
`.pagedjs_page_content` (the body zone between header and footer margin boxes) and
margin-box elements for `@top-left`, `@top-right`, `@bottom-left`, `@bottom-right`.

Key implication: CSS rules on `.page--cover`, `.section-start`, etc. apply to the
CONTENT AREA only — not to the full page including margin bands. This is the root cause
of the background-fill, header-clearance, and footer-collision bugs below.

---

## Paged.js Tier 1 — renderer-specific ship-blockers

### PJ-1: Content-area-only background (white bands on coloured pages)

**Visual symptom:** On any page with a non-white background (cream cover, dark section-break),
the header and footer margin bands remain white while the content area shows the brand colour.
The page looks like a coloured rectangle floating inside white strips. Invisible in browser
preview (no margin boxes in screen mode); only appears in the PDF.

**Detection:** On any coloured page, look for a colour seam at the top and bottom ~15mm
of the page. At 300 DPI this is clearly a step; at low DPI it may read as a warm/cool boundary.

**Root cause:** `.page--cover { background: var(--cream-50) }` in `documents.css` colours
only the `.pagedjs_page_content` element. The `.pagedjs_page` wrapper (which includes margin
bands) is untouched.

**Fix — target the `.pagedjs_page` wrapper:**
```css
/* In documents-paged.css — NOT documents.css */
.pagedjs_page:has(.page--cover) {
  background: var(--cream-50) !important;
}
.pagedjs_page:has(.page--section-break) {
  background: var(--ink-800) !important;
}
```
This mirrors the existing pattern used to suppress margin-box display on cover pages.
Apply the same background value that `documents.css` sets on `.page--cover` / `.page--section-break`.

**Confidence: `confident`** — visible colour seam is binary at 300 DPI.
**Action: HOLD** (client-facing) / **FIX IF TIME** (internal)

---

### PJ-2: Header clearance gap too tight on continuation pages

**Visual symptom:** On continuation pages (pages beginning mid-flow, not at a section
opener), the first body content element — a sentence fragment, a sub-heading, a paragraph
continuation — sits flush against the header rule with no visible breathing gap.

**Root cause:** The `.pagedjs_page_content` element (the content zone below the header
margin box) has no top padding. When Paged.js places a content fragment on a new page,
that fragment inherits no top padding from the page container — its own `padding-top` was
consumed at its opening on the previous page.

**Three failure cases — all fixed by the universal rule below:**
1. Fixed-height pages (`.page` with `.page-body` wrapper): `.page-body` sits flush at top of content area
2. Flowing section openers (`section-start` without `.page`): section's first child sits flush
3. **Continuation pages of flowing sections** (`doc-q-section`, `prose-grid` breaking mid-flow):
   content fragment placed by Paged.js has no top padding. This is the most commonly missed case.

**Universal fix:**
```css
.pagedjs_page:not(:has(.page--cover)) .pagedjs_page_content {
  padding-top: 6mm;
}
```

**After applying this fix, update max-height on fixed-height pages:**
Formula: `max-height = page-height − margin-top − margin-bottom − padding-top`
Example (A4 landscape, 28mm top, 22mm bottom, 6mm padding):
`max-height = 210 − 28 − 22 − 6 = 154mm`

**Do NOT touch these — they control the wrong gap:**
- `@top-left` / `@top-right` `padding-bottom` — moves header text down inside the margin box
- `@page margin-top` — moves the logo up/down, not content below the rule

**Double-gap structural smell — detect with grep:**
```bash
# Detect section-start sections (without .page) that contain a .page-body child
grep -n "section-start\|page-body" index.html | grep -v "page section-start"
# A .page-body line immediately after a non-fixed section-start = double padding accumulation
```
Any `<div class="page-body">` that is a direct child of a `section-start` (without `.page`)
doubles the gap to ~12mm. Fix: remove the `.page-body` wrapper from the flowing section.

**Confidence: `likely`** — breathing room involves visual judgment; flag as `confident` only when rule and content share the same visual band (zero visible gap).
**Action: FIX IF TIME** (HOLD on client-facing)

---

### PJ-3: Orphan border-top on continuation pages

**Visual symptom:** A thin horizontal rule (~1–2px) appears in the top 15mm of a continuation
page, between the header rule and the first body text. It is NOT the header rule — it is a
`border-top` from a CSS block element (e.g. `doc-q-section`) re-painting on every continuation
fragment.

**CRITICAL:** This defect is only ~1–2px thick. At full-page zoom it reads as a density
artefact. You MUST mentally zoom into the top 15mm of every continuation page.

**Detection:** Structure is: [header rule] → [6mm gap] → [orphan rule ← FINDING] → [body text]
A legitimate Q-section separator always has an eyebrow label between the rule and body text.
An orphan border appears above body text with no label.

**Why `box-decoration-break: slice` does NOT fix this:**
Chromium's print renderer does not honour `box-decoration-break: slice` on fragmented block
elements in Paged.js documents. It re-paints `border-top` on every continuation fragment
regardless. Do not apply this as a fix.

**Correct fix — use a real DOM element:**
Remove `border-top` and `padding-top` from the fragmented CSS element entirely.
Replace with a `<hr class="doc-q-separator">` as the first child of each section needing
a visible separator:

```css
.doc-q-section { margin-top: 0; padding-top: 0; /* no border-top */ }
.doc-q-separator {
  border: none;
  border-top: 1px solid var(--border-subtle);
  margin: 32px 0 24px 0;
  break-after: avoid;
}
```

Note: the first Q-section in each major section (Q1, Open Q1, etc.) does NOT get a `<hr>` —
it follows directly from the section opener. Only Q2+ get separators.

**Source smell:** any element with both `border-top` AND no `break-inside: avoid` in a
Paged.js document is a candidate — Chromium re-paints the border on every continuation page.

**Confidence: `confident`** once zoomed to 300 DPI.
**Action: HOLD**

---

### PJ-4: Flowing section footer collision

**Visual symptom:** The last visible element on a flowing section page (heading, eyebrow label,
sentence fragment) sits inside the footer margin band, overprinting footer text. The content
is legible but in the wrong zone. This is DISTINCT from fixed-height page clipping (which is
silent via `max-height + overflow: hidden`).

**Detection:** On any flowing section page (`section-start` without `.page`), look at the
bottom 8–10% of page height. Is any body element (heading, eyebrow, sentence) below the clear
body content zone, inside the footer strip? The tell: seeing both the document footer text
AND a body element on adjacent horizontal bands.

**Root cause:** A `section-start` element overflows its page, and the following sibling section
has no `break-before: page`. Paged.js flows the sibling's heading into remaining space — which
is inside the footer margin band.

**Fix options (in order of preference):**
1. Convert the intro page to `.page section-start` with `.page-body` wrapper — gives it
   `max-height: 154mm` which forces the next section to a fresh page
2. Add the `section-start` class to the overflowing section — the only reliably-honoured
   `break-before: page` mechanism in Paged.js/Chromium

**Do NOT use:** inline `style="break-before: page"` or CSS `break-before` on a non-`section-start`
element — Chromium's print renderer silently ignores these on arbitrary block elements.
This has been confirmed in practice: inline style on `doc-q-section` was ignored;
adding `section-start` to the class list worked immediately.

**Paired finding — sparse following page:** When a flowing section overruns into the footer,
the content forced to the next page often produces a sparse page. A notably sparse page
directly after a footer-collision page is diagnostic confirmation, not a separate finding —
surface both together.

**Confidence: `confident`** (visible overlap of body content and footer text)
**Action: HOLD**

---

### PJ-5: Major section opener missing page break

**Visual symptom:** A major section heading (numbered: "Section 05", "Chapter 3", "Part II")
appears in the bottom 30% of a page, after body content from the previous section.

**Root cause:** The section wrapper uses `doc-q-section` or plain `<section>` (no
`break-before: page`) instead of `section-start`. The `break-before: avoid-page` on
`.doc-title` / `.doc-eyebrow` compounds this — it tells Paged.js not to break just before
the heading, pulling it into whatever space remains on the previous page.

**Fix:** Change wrapper class from `doc-q-section` to `section-start` (which has
`break-before: page`). Check that `doc-q-section` styling (border-top, margin-top) is
no longer needed once the section gets a fresh page — it usually isn't.

**Source audit (run when HTML source is available):**
```bash
# Find all top-level numbered sections and check their wrapper class
grep -n "Section [0-9][0-9]\|Chapter\|Part [IVX]" index.html | head -30
# For each match, check the parent element's class list — must include section-start
# Any using doc-q-section, plain <section>, or no break-before: page = latent bug
```

**Confidence: `confident`** (heading position is deterministic at 300 DPI)
**Action: HOLD**

---

### PJ-6: Long-form section missing running headers/footers on continuation pages

**Visual symptom:** A long-form section spans multiple PDF pages, but continuation pages
(pages 2, 3, … of that section) show no logo or section label at the top, and/or no
document title at the bottom. Only the first and last pages of the section have headers/footers.

**Root cause:** `position: absolute` headers/footers only anchor correctly inside a
fixed-height container. When a section has `height: auto` and flows across multiple print
pages, the header appears only on the first PDF page and the footer only on the last.

**Fix:** Split each long-form section into explicit fixed-height `<section class="page">`
elements, each with its own `<header class="page-head">` and `<footer class="page-foot">`.

**What does NOT work in Chrome/Paged.js:**
- `position: fixed` in print mode — Chrome stamps the last fixed element on all pages
- CSS `@page` running elements (`element()` function) — not supported in Chrome

**BEYOND VISUAL note:** If the renderer is Chrome/Paged.js and the document has long-form
flowing sections, flag as a structural infrastructure finding. Proper running headers/footers
require either section splitting in HTML or switching to Prince or WeasyPrint.

**Confidence: `confident`** (absent header/footer is binary)
**Action: HOLD**

---

## Paged.js Tier 2 — renderer-specific quality issues

### PJ-7: Long-form body text in narrow single column — right margin wasted

**Visual symptom:** Long-form sections show body paragraphs occupying only the left ~60–70%
of the page width, with a consistent dead right margin >25% of page width containing no content.

**Root cause:** Body paragraphs using `max-width: Nch` constrained to single-column width.

**Fix:** Switch to two-column layout:
```css
/* columns does NOT work with display: flex — set display: block first */
.page-body { display: block; columns: 2; column-gap: 28px; }
```
Or use `doc-cols-2` wrapper divs for sections where explicit column control is needed.

**Confidence: `likely`** (whether single-column is intentional depends on document type)
**Action: FIX IF TIME**
