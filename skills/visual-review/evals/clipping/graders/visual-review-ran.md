---
type: regex
pattern: "TEXT-ONLY"
match: not_contains
target:
  source: file
  path: review.md
---
The report is a visual review, not a text-only pass.
