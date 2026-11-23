# Optional session handoff block

Load this file only when the user says "output handoff block" or "generate handoff". Do not emit the block by default. Most users review different documents each time, so a YAML block on every report is clutter.

Generate it when the user asks, or when they are reviewing a revised version of the same document and request a delta comparison.

## Output

```yaml
# Visual Review: Session Handoff
# Paste this block at the start of your next /visual-review invocation
# on the SAME document to get a delta comparison.

document:
  name: "<document name from report header>"
  page_count: N
  render_timestamp: "YYYY-MM-DD HH:MM"

findings:
  - id: HOLD-1
    status: open       # open | fixed | deferred | wont-fix
    summary: "<one-line summary from report>"
    pages: [N, M]
  - id: HOLD-2
    status: open
    summary: "<summary>"
    pages: [N]
  # ... one entry per HOLD and FIX IF TIME finding
```

## On the next invocation with a pasted block

- Note which findings are marked `fixed` and verify them in the new render.
- Note which are `deferred` or `wont-fix` and do not re-report them unless they worsen.
- Add genuinely new findings.
- End Phase 8 with a delta summary, for example "3 prior findings resolved, 1 deferred finding worsened to HOLD, 2 new findings".

A re-review still requires a fresh invocation on the updated source.
