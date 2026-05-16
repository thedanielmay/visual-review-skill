# Book / manuscript specifics

Use this reference when the input is a book — a manuscript intended for print (typically KDP, IngramSpark, or another POD platform), or a digital-first book PDF.

The universal Tier 1-3 checklist in SKILL.md still applies. This file adds book-specific checks: print mechanics, typographic conventions for long-form reading, and structural integrity across many pages.

## Page geometry assumptions

Default assumed page sizes for books (override from `metadata.json`):
- KDP 6×9 in: 152×229mm (the most common trade paperback)
- KDP 5×8 in: 127×203mm
- A5: 148×210mm
- KDP large print 8.5×11 in: 216×279mm

Always check `metadata.json` for the actual page size — print specifications vary. If the page size doesn't match a standard, note it; some printers reject non-standard sizes.

## Tier 1 (book-specific) — ship-blockers

Critical for print. Anything in this list will result in a rejected print proof or a visibly defective book.

- **Bleed area violation.** Print PDFs need a 3mm (0.125in) bleed on all four sides for full-bleed art (background colour or imagery extending to the page edge). If background art stops at the trim line instead of extending into the bleed, white slivers appear at the edge after trimming. Check `metadata.json` page size — if it matches trim size exactly (no bleed), full-bleed art will be cropped to white edges.
- **Safe-area violation.** Critical content (text, key imagery) within ~5mm of the trim edge or ~12mm of the spine on the inside margin (gutter). Trimming tolerance and spine roll-in will eat that content.
- **Gutter violation.** On left-hand (verso) pages, content too close to the right edge; on right-hand (recto) pages, content too close to the left edge. The book's spine eats inner margin space — body type should be no closer than 18-20mm to the spine for a 6×9 perfect-bound book.
- **Page count parity.** Print books typically need page counts in multiples of 4 (signatures). If the manuscript is, say, 287 pages, the binder will add blank pages — check whether the user wants those at the end, or wants the content padded to a clean count.
- **Recto/verso violations.** New chapters traditionally start on a recto (right-hand, odd-numbered) page. If a chapter starts on a verso, surface as Tier 1 — easy to miss in PDF review, embarrassing in print.
- **Running header/footer collision.** Running titles or page numbers landing on body content. Common in chapter-opening pages where the chapter title is large and forces the body down.
- **Image bleed mismatch.** Embedded images that should be full-bleed but are inset, or inset images that bleed accidentally.

## Tier 2 (book-specific) — typography for long-form reading

These are quality-of-reading issues. They don't break the book but they make it less pleasurable.

- **Widows.** A short last line (1-2 words) at the *top* of a page (orphaned from the rest of its paragraph on the previous page).
- **Orphans.** A short first line (the first line of a paragraph) at the *bottom* of a page (separated from the rest of the paragraph on the next page).
- **Rivers.** Vertical white channels running through a paragraph caused by aligned spaces in justified text. Hard to see on rendered pages but worth checking display type.
- **Hyphenation density.** More than 3 hyphens in a row (3+ consecutive lines ending with a hyphen) is uncomfortable.
- **Hyphenation across page breaks.** A word hyphenated at the end of a recto page, completed at the top of the next verso. Avoid where possible.
- **Type colour evenness.** Across a paragraph, the visual "greyness" should be even. Big variations suggest inconsistent kerning or tracking.
- **Tight or loose line spacing inconsistency.** Body text leading should be consistent throughout. Any chapter where the leading visibly differs from siblings is `likely` accidental.

## Tier 3 (book-specific) — layout & structural

- **Chapter-opening consistency.** Every chapter opener should have the same drop cap (or no drop cap), same vertical position of the title, same leading before body starts. Drift across chapters is `likely` accidental.
- **Page-number style consistency.** Roman numerals in front matter, Arabic in body — surface any deviation. Page-number alignment (centred vs outer-margin) should be consistent.
- **Running header style.** If the running header alternates (book title on verso, chapter title on recto), check it does so consistently.
- **TOC accuracy.** Page numbers in the table of contents must match the actual page where each chapter starts. Surface mismatches as Tier 3 (they're embarrassing but recoverable in a reprint).
- **Section-break treatment.** Within-chapter section breaks (`* * *` or extra leading) should be handled consistently throughout.
- **Front-matter and back-matter completeness.** Title page, copyright page, dedication, TOC, preface — check for presence/order. Back matter: about-the-author, acknowledgements, index. If something is in the manuscript but visibly absent from the rendered PDF, surface it.

## Tier 4 (book-specific) — brand & finish

- **Cover design** is usually a separate file (KDP requires a separate cover PDF). If the user supplies the cover for review, check spine width math (depends on page count and paper weight) and bleed/safe-area for the cover.
- **ISBN block** position on the back cover — bottom-right is convention, must include white space behind it for the barcode.
- **Font embedding.** All fonts must be embedded in the print PDF or the printer will substitute. Check `metadata.json` — every font listed must show as "embedded" in the PDF.

## Book-specific don't-flag list

- A short line at a paragraph's natural end (not a widow if the paragraph ends mid-page).
- A blank verso page before a new chapter — that's the recto-start convention working correctly.
- Front matter with non-Arabic page numbers (i, ii, iii) — convention.
- A chapter starting partway down a page if the design specifies "no chapter break, just a heading" — confirm with the user before flagging.

## Commercial press handoff checklist

Use this when the document is going to a commercial offset printer (not KDP/POD). POD platforms (KDP, IngramSpark) have their own prepress workflows and are more forgiving; commercial offset press requires all items below to be explicitly confirmed.

This checklist does not make a file press-ready — it identifies what must be confirmed before delivery. A prepress professional or print buyer should validate the final file.

**1. Page geometry**
- [ ] **TrimBox** set to the final trim size (e.g. 210×297mm for A4). Not the same as the MediaBox (which includes bleed).
- [ ] **BleedBox** set at 3mm (EU standard) or 0.125in (US standard) outside the TrimBox on all four sides where full-bleed art exists. 5mm for perfect-bound covers.
- [ ] **Crop marks** present and offset outside the bleed area (not cutting through it).
- [ ] Confirm trim size with the printer — reject non-standard sizes before building.

**2. Colour**
- [ ] **ICC OutputIntent** embedded and matching the press condition. Ask the printer for their profile: common choices are FOGRA51 (coated EU), FOGRA39 (coated EU older presses), PSO Uncoated v3 (uncoated EU), GRACoL 2006 (US coated), SWOP v2 (US publications).
- [ ] **Total Area Coverage (TAC)** within the printer's limit. Typical: ≤300% coated, ≤260% uncoated. Rich black (`C:60 M:40 Y:40 K:100`) at 240% is safe; 4-colour black at 400% is not.
- [ ] **Overprint** behaviour verified. Black text should overprint (not knock out). Verify in Acrobat's Overprint Preview or Separations Preview. A white object incorrectly set to overprint disappears on press.
- [ ] **Spot colours** named exactly to the printer's ink library. "PANTONE 485 C" and "Pantone 485 C" are treated as different inks by RIP software. Confirm naming with the printer before delivery.
- [ ] **Images** in CMYK or greyscale (not RGB) for a CMYK press. RGB images will be converted by the RIP, often incorrectly.

**3. Fonts**
- [ ] All fonts embedded and subsetted in the PDF. Check via `pdffonts` — every font must show `emb: yes`.
- [ ] No Type 3 fonts (bitmapped, not scalable). These are rejected by most presses.

**4. Images**
- [ ] Raster image resolution: minimum 300 DPI at final print size. 600 DPI for fine line art (logos, diagrams).
- [ ] No JPEG compression artefacts visible at 100% zoom — these print.

**5. PDF/X conformance (if required by printer)**
- [ ] Confirm which spec the printer requires: PDF/X-1a (2001, CMYK only, no live transparency), PDF/X-3 (2002), or PDF/X-4 (2010, supports live transparency — current standard for most EU printers).
- [ ] PDF/X-1a flattens all transparency to CMYK at a specified resolution — drop shadows and gradients are rasterised at flatten boundaries. Verify flatten results visually.
- [ ] Note: any HTML-to-PDF tool's output can be post-processed to PDF/X-4 via Ghostscript. "Prince is required for PDF/X" is false.

**6. Prepress review**
- [ ] Send a digital proof (softproof) to the printer for approval before committing to a full run.
- [ ] Request a hard proof (Epson contract proof or similar) for colour-critical work.

## What to ask the user before reviewing a book

- "Is this for print (KDP, IngramSpark, commercial press) or digital-only (PDF, EPUB)?" Determines whether bleed/safe-area/gutter checks and the commercial press checklist apply.
- "What's the trim size?" Confirms what to expect from `metadata.json`.
- "Is the cover in scope, or just the interior?"

Pick one. The first is the most important.
