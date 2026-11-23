# Worked examples of CSS causes

Load this file in Phase 3 when a symptom matches a known pattern. These are examples of causes, not required class names. Never grep for a class from this file and mark a check passed when it is absent. Check the visible symptom first.

## Padding added twice above the first body element

A flowing section wrapper and its inner content wrapper each add top padding. The gap below the header rule becomes about twice the sibling gap.

```css
[section wrapper] { padding-top: 6mm; }
[content wrapper] { padding-top: 6mm; }
```

Fix: remove the inner wrapper from the flowing section, or keep one padding source.

## Border repainted on every continuation fragment

A block with a top border and no `break-inside: avoid` repeats the border on each page fragment. It appears as a thin rule between the header rule and the first body text, with no label above it.

```css
[fragmented block] { border-top: 1px solid; margin-top: 0; padding-top: 0; }
```

Fix: remove the border from the block and add a real separator element as the first child of each section that needs one. Give the separator `break-after: avoid`. `box-decoration-break: slice` does not work in Chromium print.

## Callout heading floats away from the top edge

A heading inside a callout keeps its own top margin. That margin stacks on the box padding. The top gap becomes more than 1.5 times the bottom gap.

```css
[callout] { padding: 9pt 12pt; }
[callout] [heading]:first-child { margin-top: 0; }
```

## Stack spacing drifts between sibling pages

Sibling pages share an eyebrow, heading, and lead structure. One page uses a stack wrapper with a larger gap value. Compare the top 20% of each page as a batch. Match the wrapper gap to the siblings.

## Rules cross glyphs in a card stack

A card stack with a fixed `bottom` anchor caps the available height. Flex children whose content exceeds that cap overflow downward. Each card's top border lands on the previous card's last line.

```css
[card stack] { position: absolute; top: Npx; bottom: Mpx; display: flex; flex-direction: column; }
[card] { border-top: 4px solid; }
```

Fix: drop the `bottom` anchor and let the stack grow, shorten the card content, or widen the stack so cards wrap to fewer lines.

## Footer text used as a collision tell

A body element sitting inside the footer band often appears next to the document footer text. A footer reads like this in a rendered page:

```
[DOCUMENT TITLE] - [VERSION] - [RECORD TYPE]                     [PAGE N]
```

Use the shape of the footer as the tell, not the words. Any body element in that band is a footer collision.

## Long-form text wastes the right margin

Body paragraphs limited to a narrow single-column width leave a dead right margin. Switch to two columns. Set `display: block` before `columns`, because `columns` does not work on a flex container.

```css
[content wrapper] { display: block; columns: 2; column-gap: 28px; }
```

## Brand swatch used as a panel fill

A mid-tone swatch used for a wide panel looks muddy and kills small controls. The same system usually offers a pale tint. Keep the full swatch for accents such as chip borders and eyebrow underlines.
