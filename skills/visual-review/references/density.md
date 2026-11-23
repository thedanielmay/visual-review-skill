# Density and sparse page analysis

Load this file in Phase 3B when a page looks sparse or cramped. Cramping and whitespace pooling usually come as a pair. One page bunches at the top while another has unused vertical space. Neither looks wrong alone. The comparison is the finding.

## Operational rule

1. For each body page, note the bottom dead-whitespace gap between the last content element and the footer rule.
2. Compute the median across body pages. Skip covers, dividers, and structurally different pages.
3. Flag a page with a gap over about twice the median as excessive whitespace, Tier 2. Pair it with the pages below the median.
4. Flag a page with a gap under half the median as cramping, Tier 2. This direction matters more because cramped pages tire the reader.
5. Report both directions. Suggest moving content from cramped pages into spacious ones, or adjusting row spacing until the gaps even out.

Confidence: `likely`. Flag as `confident` only when the dead-whitespace gap exceeds 30% of page height.

## Diagnose a sparse page first

A sparse page needs a cause before it needs a fix.

**Step 1: count rows.** If the page holds a table or numbered list, count source rows against visible rows. A difference means the page is falsely sparse. Content exists but is clipped. Scaling type up makes the clipping worse. Split the page.

**Step 2: run the overflow audit.** Run the HTML source overflow audit from Phase 0. Positive overflow confirms false sparseness. Do not scale up.

**Step 3: scale only when genuinely sparse.** If source and render row counts match and overflow is zero, the page is genuinely sparse. Redistribute content, adjust row padding, or adjust stack gaps to even out the page.

```
Sparse page detected
    |
Count source rows against visible rows
    |
Counts differ -> FALSELY SPARSE -> split the page
    |
Counts match -> run the overflow audit
    |
Overflow above 0 -> FALSELY SPARSE -> split the page
    |
Overflow is 0 -> GENUINELY SPARSE -> adjust layout spacing
```

Never enlarge body text to fill empty space. That is a layout problem, not a type-size problem. On a falsely sparse page, enlarging text hides more rows below the clip boundary. The reader still loses content.

## Whitespace with small type

When a page has both significant unused space and body text smaller than its siblings, report one Tier 2 finding. Describe the imbalance and give the layout options. Do not report the whitespace and the small type as two separate findings, and do not enlarge the type to fill the page.

## Reporting

An actionable finding stays actionable even when this skill cannot apply the fix. Say so plainly. The user finishes the report knowing which page is cramped, which page has room, and what to move. Keep the finding at Tier 2. The whole-document feeling of rushed and sparse pages is exactly what this pass exists to catch.
