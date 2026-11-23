# Confidence rubric

Every finding is labelled `confident`, `likely`, or `possible`. The label answers one question: *how sure is the user that this is real before they look?*

Confidence is independent of severity. A `possible` Tier 1 finding still belongs in Tier 1, but the label tells the user to look closely before acting on it.

## `confident`, you can prove it

The render shows it unambiguously. A reasonable person looking at the same crop would agree without further context.

Hallmarks:
- Binary, observable in pixels: clipped text, visible overlap, missing image (broken-image icon), white background where the brand colour belongs.
- Provable from metadata: font fallback (the metadata says Arial was used; the design says it must be Söhne), low-DPI image (metadata says 72 DPI at print scale).
- Not subject to design intent, it is just wrong.

Examples:
- "The phrase 'including GST' is cut off by the page's right edge on page 7." (Cropped image shows letters running off the page.)
- "The logo on page 4 is missing, broken-image icon visible at the top-left."
- "Font Söhne is referenced in CSS but Arial appears in the rendered metadata for pages 8-12."

If you write `confident` and the user looks and disagrees, your calibration is off. Default down a level when uncertain.

## `likely`, strong signal, contextual

You can see the issue clearly, but whether it is a problem depends on context the user has and you do not.

Hallmarks:
- Visual signal is clear, but design intent is ambiguous.
- Comparison to siblings (other pages, the brand spec) shows drift, but the drift can be intentional.
- Typography judgments (orphans, hyphenation, awkward breaks) where reasonable designers can disagree on the threshold.

Examples:
- "The word 'system' is alone on the last line of the paragraph on page 3, likely orphan." (This can be intentional emphasis, but usually is not.)
- "Footer y-coordinate is 278mm on page 5; all other body pages have it at 275mm." (Likely drift; can be intentional if page 5 has a structural difference.)
- "Profile cards on page 12 are not equal-width: leftmost is 92mm, others are 88mm." (Likely accidental; can be intentional emphasis.)

Most Tier 2 and Tier 3 findings are `likely`.

## `possible`, surfacing for awareness

You are not sure if it is a problem. The signal is weak, subjective, or you'd want a second opinion. You are flagging it so the user can dismiss it on a fast skim if they want.

Hallmarks:
- Aesthetic judgments without a clear rule violation.
- Whitespace "feeling" too cramped or too loose.
- Hierarchy concerns where the design can intentionally invert convention.
- Findings where you are uncertain whether what you see is a render artefact or a real issue.

Examples:
- "Page 8 feels half-empty compared to its siblings, possible excessive whitespace."
- "The ratio between the eyebrow and body type on page 14 is tighter than on other pages, possible hierarchy drift, but can be deliberate for this layout."
- "Faint horizontal line across the middle of page 6, possibly a rule, possibly a render artefact."

`possible` findings are easy to ignore. That is the point, they're a low-cost way to surface things without crying wolf. If you find yourself labelling many findings `possible`, consider whether you are seeing real signal or pattern-matching the checklist.

## How to use this when writing findings

1. Describe what you see. Concretely.
2. Decide: can a reasonable person disagree this is a problem? If no → `confident`. If yes, but the visual signal is strong → `likely`. If yes and you are not sure yourself → `possible`.
3. Default down when uncertain. A user who sees `confident` and disagrees loses trust in the report. A user who sees `possible` and dismisses it loses nothing.
4. If something is genuinely ambiguous, prefer `possible` and *describe* the ambiguity. "Possible because the resolution makes it hard to confirm, recommend re-rendering at 300 DPI to verify."

## What confidence is NOT

- It is NOT severity. Tier 1 ≠ confident.
- It is NOT priority. The user prioritises by tier, then by confidence within tier.
- It is NOT certainty about your suggested fix. A finding can be `confident` while the suggested fix is one of several valid options.
