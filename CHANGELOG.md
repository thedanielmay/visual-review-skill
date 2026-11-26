# Changelog

## 2.2.1 - 2026-11-26

- Numeric ranges in the user's own documents follow their written dash rule. In other documents the en dash stays.

## 2.2.0 - 2026-11-23

- Cuts SKILL.md under 500 lines. Detail now loads from references only when it applies.
- Fixes the HTML render command to use `playwright pdf`, verified on a sample file.
- Tiles 300 DPI renders inside the image limit and uses Read as the fallback renderer.
- Crops all four page edges using each page's measured size, so portrait footers are checked.
- Removes one project's class names, footer text and style taste from the checks.
- Rebuilds evals in the `claude plugin eval` format with three PDFs that carry known defects.
- Resolves contradictory rules, dead file names and stale history notes.
- Adds print preflight to every mode with `pdfinfo -box`, `pdffonts` and `pdfimages -list`.
- Asks document context with the mode question and uses defaults for proactive runs.
- Narrows HOLD to rejected-job problems and uses the trade term runt for a short last line.
- Replaces the local stack survey with a one-line handoff to visual-stack-review.
- Uses the same Playwright command for the environment probe and the HTML render, and reads metadata from the rendered PDF.
- Creates the render folder in the HTML path. Full Review tiles every page; Quick Pass crops only pages that look wrong.
- Adds a no-magick fallback with a short zone check by eye.
- Aligns the HOLD rule across every checklist and restores two Phase 4 cross-page checks.
- Handles long-form pages in the overflow audit and shows the renderer in the report header.

## 2.1.4 - 2026-11-23

- Adds the marketplace icon approved by Daniel (thedanielmay/agent-tools#2).

## 2.1.3 - 2026-11-23

- Marketplace file gains a description, so the full check passes again (thedanielmay/agent-tools#10).

## 2.1.2 - 2026-11-22

- Added a marketplace manifest, an MIT licence and this changelog.
- Added `license` to the SKILL.md frontmatter and moved the version to 2.1.2.
- Removed the author email from `plugin.json` and the README, and added the author URL, homepage, repository and licence.
- Replaced personal file paths and an email address in `evals/evals.json` with generic placeholders.
- Removed version numbers from the README prose and added an Install section.

Earlier versions: see git tags.
