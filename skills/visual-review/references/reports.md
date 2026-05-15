# Report / proposal specifics

Use this reference when the input is a multi-page report, proposal, business document, brochure, or other structured long-form (not a slide deck, not a book).

The universal Tier 1-3 checklist in SKILL.md still applies. This file adds report-specific checks for documents with formal structure (cover, TOC, sections, references, appendices).

## Page geometry assumptions

Default assumed page sizes for reports (override from `metadata.json`):
- A4 portrait: 210×297mm (most common outside US)
- US Letter portrait: 216×279mm (US default)
- A4 landscape: 297×210mm (data-heavy reports, dashboards)

Reports rarely use bleed (no edge-to-edge ink), so bleed/safe-area is not a Tier 1 concern unless the cover is in scope.

## Tier 1 (report-specific) — ship-blockers

- **Cover page integrity.** Title, subtitle, client name, date, version — all rendered, none clipped, none mis-merged from a template.
- **TOC accuracy.** Section titles and page numbers in the TOC match the actual section titles and pages in the body. A TOC pointing to "page 14" when the section is on page 16 is Tier 1 — readers will lose trust immediately.
- **Section header continuity.** Every major section starts with the same heading style. If section 3 has a different style from sections 1, 2, 4, that's Tier 1.
- **Running header/footer continuity.** Running headers (typically section title or document title) should appear on every body page, formatted consistently. Missing headers on individual pages = Tier 1.
- **Page number continuity.** No skipped or duplicated page numbers. Front matter (cover, TOC, executive summary) may use Roman numerals; body uses Arabic. Both must be continuous within their range.
- **Cross-references resolve.** "See section 3.2 on page 14" must point to the right page. "See Figure 5" must point to a figure that exists and is labelled "Figure 5".
- **Versioning visibility.** Version number (e.g. "v1.6.1") should appear on the cover and in the footer of every body page. Mismatch between cover version and footer version = Tier 1.
- **Confidentiality / classification banners.** If the document is marked "Confidential" or "For internal use only", every page must carry that mark. Missing on any page = Tier 1.

## Tier 2 (report-specific) — typography & content

- **Heading hierarchy compliance.** H1 → H2 → H3 should not skip levels (no H1 followed directly by H3). Surface skips as `likely` Tier 2.
- **Numbering consistency.** Section numbering (1, 1.1, 1.2, 2, 2.1) must be continuous, no gaps. Numbered lists within the same section restart cleanly.
- **Caption presence.** Figures and tables should have captions. A figure without a caption is `likely` an oversight.
- **Footnote/endnote consistency.** All footnotes use the same numbering scheme (continuous through document, or restart per page/section — pick one). Footnote markers in body match notes at page bottom.
- **Pull-quote treatment consistency.** If the document uses pull quotes, they should all be styled identically.
- **Date format consistency.** All dates in the document should follow the same format (per house-rules.md: `4 May 2026` for prose, ISO for machine).

## Tier 3 (report-specific) — layout & rhythm

- **Section-opening consistency.** Every section starts with the same vertical position, same heading treatment, same spacing before first body paragraph.
- **Sidebar/callout consistency.** If the document uses sidebars or pull-out callouts, they should all be styled consistently and positioned consistently.
- **Image scaling consistency.** Images should fit a small number of standard sizes (e.g. half-width, full-width, full-bleed). Random scaling looks amateur.
- **Table styling consistency.** All tables use the same header style, same row banding (or none), same border treatment.
- **Column left-edge drift.** On any document using a rail or two-column layout, the right column's left edge must be at the same x-coordinate on every page. A gap variation of even 8–12px is visible when pages are compared side-by-side. Explicit check: look at the first line of right-column body text across all body pages — if the text starts at a noticeably different horizontal position on any page, it is Tier 2 (Tier 1 if the document uses left-aligned headings that make the misalignment immediately apparent). This check applies in Quick Pass — it does not require cross-page diffing, just noting the right-column x-position while passing through each page. Source smell: mixed `gap` values on the same component class — some pages using the CSS default, others overriding inline with `gap: Npx !important`. The fix is to remove all inline gap overrides and standardise on the CSS class value.

## Tier 4 (report-specific) — brand & finish

- **Logo on every page** (or wherever the brand template specifies — match the template).
- **Colour palette compliance.** Charts and graphs should use the brand palette. Surface any chart colour not in the palette as `likely` drift.
- **Chart type consistency.** If three financial charts are bar charts and a fourth is a pie chart, surface as `possible` — might be intentional, often isn't.
- **Image treatment consistency.** If photos throughout have a particular treatment (B&W, duotone, full colour with subtle border), every photo should follow.
- **Whitespace policy compliance.** If the brand template specifies generous whitespace, cramped pages stand out. Vice versa.

## Specific to proposals (subset of reports)

If the document is a client-facing proposal:

- **Client name correctness.** Search for the client's name throughout. A misspelling on page 1 is fine; a misspelling on page 14 is embarrassing. Surface every variant found.
- **Pricing block clarity.** Pricing should never be ambiguous. Surface pricing tables/blocks as `confident` if any number is hard to read, mis-aligned, or could be confused.
- **Currency consistency.** Per house-rules.md: AUD by default, explicit currency code if non-AUD. Mixed currencies in the same proposal without labels = Tier 1.
- **Signature block presence.** If the proposal expects a signature, the signature block must be present, complete, and on a single page (not split across pages).
- **Date currency.** "Valid until [date]" — surface as `likely` Tier 2 if the date is in the past or within a week.

## Report-specific don't-flag list

- A blank page intentionally inserted to start a section on a recto in a print-bound report.
- Front-matter pages without page numbers (cover, blank, copyright) — convention.
- A glossary or index at the back with different layout from body — that's the convention.
- A formal "[This page intentionally left blank]" marker on a blank page — that's correct, not a glitch.

## What to ask the user before reviewing a report

- "Is this for distribution (formal, client-facing) or internal (draft, working document)?" Determines strictness.
- "Is there a brand template or previous version I can diff against?"
- "Are there any sections I should pay special attention to (pricing, scope, terms)?"

Pick one — usually the first.
