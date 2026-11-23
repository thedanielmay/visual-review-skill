# Form, interactive and colour checks

Load this file in Phase 3 when the document is a fillable artefact (field sheet, survey form, response card, intake form, scoring sheet) or a branded artefact. Skip it on plain prose documents. Most findings are `likely` or `confident`.

## Fillable forms

- **Doubled checkbox containers.** A pill, chip, or bordered button that reads as tickable and also holds an inner drawn checkbox. The reader sees two boxes where one is expected. Fix: drop the inner glyph or drop the outer border. Confidence: `confident` when source confirms the nesting.
- **Inconsistent checkbox alignment.** The same checkbox and label row sits at different baselines across the document. Mixing vertical alignment policies causes this. After a global fix, walk every row again. A parent container often overrides the change. Fix one policy and apply it to every row.
- **Inconsistent checkbox sizes.** Several box sizes in one form. A small variant can be a deliberate exception, not drift.
- **Checkbox-shaped bullets.** A heading, eyebrow, or list bullet rendered as a square outline. It reads as a field that is not there. Square bullet characters are a common cause.
- **Fields without underlines.** A label followed by blank space where the user must write. Add a rule, or mark the field as auto-filled. A rule with no label is also a finding.
- **Fields too short to write in.** Under about 25 mm for a name or date. The field exists but cannot be used.
- **Radio buttons drawn as squares, or the other way round.** Single-choice fields need a circle. Multi-choice fields need a square. Report as `likely`, since the convention is widely held but not universal.
- **Sub-options without a visual branch.** Options nested under a tickable parent need an indent or branch line. Without one they read as equal-status options.
- **Field-to-label misalignment.** A label and its field do not share a baseline or grid line. Mixing font families in one flex row without an alignment policy causes this.
- **Inline hint placement drift.** The same kind of hint appears in different positions across the document. Pick one position per hint role and apply it everywhere.
- **Wrap-fragile chip rows.** Fixed-width chips in a wrapping flex row with no shrink policy. They render fine at the design width and escape on a narrower column. Stress-test by checking each chip against its parent's right edge.

## Colour and contrast

These are design-system outcomes, not WCAG measurements. The question is whether the reader can read the thing.

- **Full-saturation brand swatch as a panel fill.** A mid-tone brand colour used for a wide panel when the system also offers a pale tint. Text stays technically legible but looks muddy, and small controls lose definition. Swap to the tint and keep the full swatch for small accents.
- **Hairline rules that vanish on tinted panels.** A rule with an alpha colour reads well on white and disappears on a tinted panel. Use a solid colour so visibility does not depend on the panel underneath.
- **Contrast that works on screen but fails in print.** Sand on cream, sky blue on white, or light grey on paper. Screen rendering smooths the difference. Matte print and photocopy remove it. Report as `possible` for print-bound work.
- **Faded eyebrow labels on tinted boxes.** Pale grey or alpha eyebrows vanish on a tinted callout. The cause is the same as the hairline rule above.
- **One swatch used at several opacities without a rule.** Pick one rule, such as full strength for accent borders and half strength for panel fills. Tier 3 when the render looks fine, Tier 2 when the inconsistency reads as drift.
