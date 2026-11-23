---
type: regex
pattern: "not be found|not found|no such file|missing input"
flags: i
match: not_contains
target:
  source: file
  path: review.md
---
The report did not claim the input PDF was absent.
