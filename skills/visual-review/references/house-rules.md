# Optional project house rules

Load this file only when the user opts in to a project style file in Phase 7. The skill does not apply these rules by default. The default dash rule lives in `SKILL.md` Phase 7.

A project can supply `HOUSE_RULES.md` at its root. Copy this template into that file and edit it. The skill reads it only after the user approves the change list. It never applies style rules in silence.

Keep the file short. Each rule needs a visible symptom and a concrete change. Rules that depend on one person's taste do not belong here unless the project has agreed to them.

## Template

```
# House rules for <project name>

## Punctuation
- [Symptom]: [change]
- Trailing periods on list items: remove when the item has one sentence.
- Heading punctuation: no trailing period or colon.

## Quotes
- Keep one quote style in the document. Do not auto-rewrite between straight and curly quotes.

## Numbers and money
- Pick one register in the document, such as $40,000 or $40k.
- State the currency code when it is not the local default.

## Capitalisation
- Headings: pick sentence case or title case and apply it everywhere.
- Acronyms: follow the established convention.

## Dates and times
- Dates: pick ISO or human-readable form and apply it everywhere.
- Times: pick 12-hour or 24-hour form and apply it everywhere.

## Locked content
- Never edit a string marked as canonical or locked. Report drift as a HOLD finding.
```

## Application

Apply only approved rules. Use the Edit tool on the source file. Log every change to `mechanical_fixes.log` with file, line, before, and after. Re-render after the edits.

A `.visualreviewignore` file at the project root wins over this file when the two conflict.
