# Core visual checklist

Load this file in Phase 3 for every page in every mode. Checks are written by visible symptom. A CSS class name, when given, is an example of a cause, not a required pattern. See `worked-examples.md` for concrete patterns.

## Tier 1: content integrity

These findings are nearly always `confident`. If you see one, treat it as real.

### Clipped content

Any text or graphic cut off at any page edge is a ship-blocker. Do not call it intentional framing. The reader sees a broken page.

**Bottom-edge completion checks.** Run these on the bottom 25% of every fixed-height page.

1. **Sentence completion.** Does the last visible sentence end with punctuation, a complete word, or a closed parenthetical? A sentence that ends mid-word or without punctuation is a HOLD finding. Do not call it a natural paragraph break.
2. **Box border completion.** If the bottom element is a box, card, callout, or table, does it have a visible bottom border or a clear close? A missing bottom border on a page of bordered cards is a HOLD finding.
3. **Column completion.** On a two-column page, does the right column hold content? An empty right column is a HOLD finding. A cover page with faint decorative bars in the empty column is not exempt. Those bars do not print. Flag a cover as Tier 2 and a body page as Tier 1.
4. **Column top alignment.** On a page where a full-width heading is followed by two columns, do both columns start at the same height? A left column that starts one line-height below the right is FIX IF TIME. Cause: padding applied to the page container before the heading. Fix: move the padding to the heading block.
5. **Footer visibility.** Is the footer visible on every body page? A missing footer is a HOLD finding.
6. **Footer content clearance.** Does body content finish above the footer strip? A last line that touches or enters the footer strip is a HOLD finding. Cause: a `max-height` set to the full page height without subtracting the footer. Fix: reduce `max-height` or add `@page margin-bottom`.
7. **Footer breathing room.** When content is not clipped, is there a visible gap between the last line and the footer rule? If the eye moves straight from text to rule, flag FIX IF TIME. Confidence: `likely`.
8. **Header clearance.** Is there a gap between the running-header rule and the first body line? Content flush against the rule is FIX IF TIME. Apply the same test to any horizontal rule on the page. A rule and a text baseline in the same band have no clearance. Fix: add top padding to the first element after the rule. Confidence: `likely`.

**Excessive header gap.** On a section opener, compare the rule-to-eyebrow distance with at least two structural siblings. A gap about twice the sibling gap is FIX IF TIME. Cause: padding added by both a flowing section wrapper and its inner content wrapper. Fix: keep one padding source. Confidence: `likely`.

**Section opener page break.** A major numbered section heading in the bottom 30% of a page is FIX IF TIME. If a missing break removes content from the page, report the lost content as HOLD. Look at the page ending with the heading, not only the clean page that follows.

**Continuation-page orphan rule.** On a page that begins mid-flow, look at the top 15 mm below the header rule. A thin rule of 1 to 2 px there is a HOLD finding when no eyebrow label sits between the rule and the body text. At full-page zoom this reads as a density artefact. Inspect the crop. Cause: a border on a block that repeats on every continuation fragment. Add `break-inside: avoid` or replace the border with a real separator element.

**Flowing section footer collision.** On a page from a flowing section, look at the bottom 8 to 10%. Any body element inside the footer band is a HOLD finding. The element stays legible but overprints the footer. A sparse page directly after the collision confirms the overflow. Report both together. Source audit: when a flowing section holds a heading plus a table or grid, check that the next section starts a new page. Flag a latent FIX IF TIME if it does not.

**Anti-rationalisation.** A clipped page looks clean. Test each excuse:

- "The content ends naturally": check for terminal punctuation.
- "The whitespace is breathing room": check for a missing column.
- "The box needs no bottom border": compare with sibling boxes.

### Table and list completeness

On any fixed-height page with a table or list:

1. Count the rows or items in source.
2. Count the rows or items in the render.
3. A difference is a HOLD finding. Name the missing rows. Do not call it density imbalance.
4. Split the page. Do not reduce font size to fit more rows.

Confidence: `confident`, because row counts are deterministic.

### Other Tier 1 checks

- **Text overrunning its container.** Content visibly escapes a fixed-width box.
- **Missing or broken image.** The logo is absent, alt text shows, or a broken-image icon appears.
- **Overlapping elements.** Two text blocks share space, or text overlaps a rule, image, or panel fill. Ask for each page whether any two bounding boxes intersect. Check corner zones, where the eye tires first.
- **Rule through glyph.** Scan each horizontal rule on a page with card dividers. Does it pass through a character above or below it, not just beside it? If glyph shapes peek out from behind the rule, flag a HOLD finding. A flex or grid stack with a fixed `bottom` anchor often causes this. See `worked-examples.md`.
- **Corner-zone clipping.** On a landscape spread, inspect all four corners. Top-right is the most missed zone.
- **Off-page element.** Anything placed outside the visible page area.
- **Header and footer collision.** A rule, page number, or running title lands on body content.
- **Long-form continuation pages.** A section that spans pages must keep its header and footer on every page. A missing one is a HOLD finding.
- **Long-form narrow column.** Body text using only 60 to 70% of the page width with a dead right margin is Tier 2. See `worked-examples.md`.
- **Background fails to reach the edge.** A branded background leaves a white band in the header or footer zone.
- **Font fallback.** Check the font list in `metadata.txt`. An unexpected substitute font is a HOLD finding.
- **Low-resolution raster.** A photo below 150 DPI at print scale is a HOLD finding for print. See `print-preflight.md`.
- **Legibility floor.** Body or item text below 10 px, or prose leading below 1.35, is a HOLD finding. This often follows an earlier overflow fix that shrank the type. Restore legible type and split the page. A page that only fits at unreadable size is broken.
- **Landscape decks.** Body text below roughly 16 px at fit-to-page is cramped. Captions and persistent navigation text need at least 13 px. Projection audiences do not zoom.
- **Illegible figure.** For each figure or diagram, ask whether its internal labels read at the rendered size. A squashed aspect ratio is a common cause. Zoom to 1:1 or 2x. Tier 2, or Tier 1 when the figure is the page's main content.
- **Structured row inconsistency.** Every row in a repeating grid shares padding, separator treatment, and baseline rhythm. Mixed separators are Tier 1 because the table reads as half-edited.
- **Count labels.** Check every "Step 3 of 5" pattern against the rendered count. A mismatch is a FIX IF TIME finding.

## Tier 2: typography

Most findings here are `likely`.

- **Awkward line breaks.** A name split across lines, a number apart from its unit, or a break that changes meaning.
- **Runt last line.** A single word alone on the last line of a paragraph. Use the trade term `runt`, not orphan or widow.
- **Widow.** A short last line stranded at the top of a page, cut off from its paragraph on the previous page.
- **Orphan.** A short first line stranded at the bottom of a page, cut off from the rest of the paragraph.
- **Mid-word hyphenation at column edges**, especially in display type.
- **Awkward column splits.** An item title in one column and its description in the other.
- **Stretched or shrunk text.** Letter spacing or font stretch differs from the same style elsewhere.
- **Heading hierarchy violation.** H2 larger than H1, or an eyebrow larger than body text.
- **Many named units in one paragraph.** Two or more bold labels that each introduce a distinct item inside one paragraph block is Tier 2. Give each item its own block with paragraph spacing. Confidence: `confident` when counting labels in source.
- **Callout padding asymmetry.** In a callout box, the gap from the top border to the heading is more than about 1.5 times the gap from the body text to the bottom border. Cause: the heading keeps its own top margin, which stacks on the box padding. Fix: zero the top margin of the first child inside the callout. Confidence: `likely`.

## Tier 3: layout and rhythm

Compare these against sibling pages. Most findings are `likely` or `possible`.

- Misaligned baselines across columns.
- Inconsistent margins between similar pages.
- Uneven gaps between repeating elements.
- Floating content pinned high with empty space below.
- Whitespace balance against sibling pages. Load `density.md` for the rule and the tier.
- Rule lines at inconsistent widths or positions.
- Footer and page-number alignment drift.
- Logo size or position drift.
- Header-to-body gap that differs between pages. Standardise the top margin on the page content container.
- Heading-block spacing drift. For pages sharing an eyebrow, heading, and lead structure, compare the vertical gaps in the top 20%. A stack wrapper with a different gap value on one page is the usual cause. This needs a batch comparison, not a page-by-page pass.
