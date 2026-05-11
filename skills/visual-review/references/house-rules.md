# House rules — Daniel's style

These are project-wide style preferences. The mechanical-fix phase applies them silently, every time. The visual-review phase flags any survivors that mechanical-fix couldn't reach (e.g. text rendered into an image).

Locale: AU English. Time format: 24-hour.

## Banned characters

The following characters are banned in body copy and headings, with no exceptions:

| Banned | Replace with | Notes |
|---|---|---|
| `—` (em-dash, U+2014) | ` - ` (spaced hyphen) | Daniel finds em-dashes ostentatious and AI-coded. |
| `–` (en-dash, U+2013) | ` - ` (spaced hyphen) | Same. Exception: don't rewrite en-dashes inside numeric ranges if the project explicitly opts in via a comment in source. |

In source files (HTML, MD, TXT) — find-and-replace these characters and log every change to `mechanical_fixes.log`.

In rendered output that doesn't trace back to source (e.g. text inside an embedded SVG or rasterised image) — flag as a Tier 2 finding ("em-dash survivor in image asset, manual fix required").

## Trailing punctuation

- `<li>` items must NOT end with a trailing period — even if the item is a complete sentence. Exception: the item contains multiple sentences, in which case all sentences end with periods (consistency wins).
- Headings (h1-h6) never end with a period or colon.

In source: scan all `<li>` for trailing `.`, strip if the item has only one sentence.

## Quote marks

Default to **straight quotes** (`"`, `'`) in all contexts. Smart quotes (`"`, `"`, `'`, `'`) are not banned, but mixed usage *within a single document* is. If the document uses smart quotes anywhere, they should be consistent throughout.

Mechanical-fix policy: do not auto-rewrite straight↔smart. Just detect inconsistency and surface as a Tier 2 finding ("mixed quote styles — pick one").

## Numbers and money

Within a single document, pick one register and stick to it:
- `$40k` and `$1.2M` (compact, suits decks and brochures)
- `$40,000` and `$1,200,000` (full, suits formal reports and proposals)
- `forty thousand` (spelled, rarely justified outside narrative prose)

Mixed registers in the same document = Tier 2 finding. Don't auto-fix — designer's call which register to keep.

Currency notation: `AUD 40k`, not `$AUD 40k` or `40k AUD`. Always specify if non-AUD: `USD 1.2M`. Bare `$` defaults to AUD only when the document declares AUD upfront.

## Capitalisation

- Headings: sentence case, not Title Case. ("How we work" not "How We Work".)
- Eyebrows / overlines: ALL CAPS, letter-spaced.
- Acronyms: established convention wins. ROI not RoI. URL not Url.
- Inconsistent capitalisation of the same term within the document = Tier 2 finding ("post-meeting" vs "Post-Meeting").

## Dashes (in compounds)

- Compound modifiers: hyphen, no spaces. "post-meeting", "high-quality", "real-time".
- Compound nouns formed from compound modifiers: keep the hyphen.
- "and/or": don't use. Pick one. If you genuinely mean both, write "X, Y, or both".

## Lists

- Lead with the noun: "Setup time" not "The setup time".
- Parallel structure: all items in a list start with the same part of speech (all nouns, all verbs in the same tense, all imperatives).
- Don't end with "etc." — list the meaningful items.

## Italic and bold

- Bold for the load-bearing word in a sentence ("This is the **only** number that matters.").
- Italic for titles of works, foreign words, and emphatic stress.
- Never italic AND bold simultaneously.
- Never underline outside hyperlinks.

## Date and time

- Dates: `2026-05-04` (ISO) in machine-facing contexts; `4 May 2026` (no comma) in human-facing prose.
- Times: 24-hour always: `14:30`, never `2:30 PM`.
- Time ranges: `09:00–17:00` with an en-dash *for ranges only* (the one allowed en-dash usage).

## Specific to slide decks

- Eyebrow on every body slide; never on title slides or section dividers.
- Footer present on every body slide; never on title slides or section dividers.
- Page numbers in the footer right-aligned, sentence case ("Page 7 of 24" or just "07/24" — pick one and stick with it).

## Specific to formal proposals/reports

- First page of each major section starts on a recto (right-hand) page in print.
- Footnotes use Arabic numerals, restart per chapter (or run continuously — pick one).
- Block quotes: indented both sides, no quote marks, attribution on a new line beginning with "—" (yes, the em-dash exception applies *only* to attribution lines, mirroring print convention).

## Locked content (canonical strings)

When source files contain comments like `<!-- LOCKED -->` / `<!-- DO NOT EDIT -->`, or a project README / memory entry declares a phrase as "verbatim" / "single source of truth" / "canonical definition", treat that string as immutable. The mechanical-fix phase MUST NOT touch these strings even if they otherwise match a find-and-replace rule (e.g. don't auto-strip a trailing period inside a locked legal phrase, don't normalise a smart quote inside a locked tagline).

The visual-review phase performs a verbatim diff of locked strings against the declared canonical version and surfaces any drift as Tier 1. See SKILL.md "Locked-content verbatim check" for the policy.

## Form artefacts (field sheets, intake forms, scoring sheets)

When the document is a fillable form, a recurring class of visual bug is **doubled tickable surfaces**: a pill or chip with its own border that contains an inner drawn checkbox glyph. The reader sees two boxes where one is expected. Source-scan smell: a parent class (`.pill`, `.chip`, `.button`, `.tag`) carrying `border:` AND containing a child element with the document's checkbox class (`.checkbox`, `.box`, `.box-chk`, `.tick`).

Mechanical-fix policy: do not auto-rewrite (the fix is structural, not a string swap). Surface as a Tier 2 finding under "Form & interactive-element semantics" (see SKILL.md). Note both the visual symptom and the source location so the designer can pick which container to keep.

## Application

The mechanical-fix script reads this file and applies all auto-fix rules in one pass. It logs every change to `mechanical_fixes.log` with file, line, before, and after. The visual-review phase then scans the rendered output for any rule violations the mechanical pass couldn't reach.

If a project has a `.visualreviewignore` file with rules that contradict house-rules.md, the project file wins for that project.
