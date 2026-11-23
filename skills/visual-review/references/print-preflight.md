# Print preflight and metadata rules

Load this file in Phase 2 for every PDF or HTML input, in every mode. Collect the metadata first, then treat each flag as a hypothesis to check against the render. Do not paste raw metadata into the report.

## Commands

Phase 2 defines `OUT` as the output folder and `PDF` as the input PDF, or the `output.pdf` made by the HTML step. Run the three tools on that PDF:

```bash
pdfinfo -box "$PDF" > "$OUT/metadata.txt"
pdffonts "$PDF" >> "$OUT/metadata.txt"
pdfimages -list "$PDF" >> "$OUT/metadata.txt"
```

`pdfinfo -box` reports MediaBox, CropBox, TrimBox, and BleedBox. `pdffonts` reports embedding and Type 3 fonts. `pdfimages -list` reports image resolution in ppi at placed size.

## HOLD rules

Apply these in Quick Pass and Full Review.

- **Font not embedded.** Any text-bearing font without `emb: yes` is a HOLD finding. The document falls back to a substitute on another machine. Spacing shifts and columns can overflow.
- **Type 3 font.** A bitmapped font is a HOLD finding for print. Most presses reject it.
- **Low-resolution raster.** An embedded image below 300 ppi at final print size is a HOLD finding for print. Fine line art needs 600 ppi. An image below 150 ppi is also a visual HOLD because it looks fuzzy on screen.
- **Missing bleed in print.** A full-bleed page whose TrimBox matches the MediaBox has no bleed. Full-bleed art will be cropped to white edges after trimming. Require 3 mm or 0.125 in on all four sides, and 5 mm for a perfect-bound cover.
- **Wrong facts.** A locked string that drifts from its canonical version is a HOLD finding. See the locked-content rule in `SKILL.md` Phase 3.
- **Wrong or missing trim and bleed boxes when print-bound.** Check BleedBox against the printer requirement. Check Crop marks sit outside the bleed area.
- **RGB images for a CMYK press.** Images in RGB are converted by the RIP, often badly. Confirm CMYK or greyscale for commercial offset work.

## Other flags

- **Tagged: no.** No semantic structure. Report as NOTE. Assistive technology is out of scope for fixes.
- **Optimised: no.** The PDF is not linearised. Report as NOTE for documents delivered by link.
- **Untitled or anonymous.** Report as NOTE. Do not hold a document for placeholder property fields.
- **Custom Producer.** A producer name hints at known behaviour. A two-pass "Page X of N" build often breaks at page 1. WeasyPrint can leave a default font when CSS omits font-family. Investigate and verify.
- **Several producers.** The PDF is composite. Pages can render inconsistently. Check the page renders.
- **Unusually small file for the page count.** Images can be missing. Worth a FIX IF TIME check.

## Commercial press checklist

Use this when the document goes to an offset printer.

- Confirm TrimBox at the final trim size and BleedBox at the required offset.
- Confirm crop marks outside the bleed area.
- Confirm the ICC OutputIntent matches the press condition. Ask the printer for the profile.
- Confirm total area coverage is inside the printer limit. Typical limits are 300% coated and 260% uncoated.
- Confirm black text overprints and no white object overprints by mistake.
- Confirm spot colour names match the printer ink library exactly.
- Confirm the required PDF/X flavour and check flatten results visually.
- Request a softproof, and a hard proof for colour-critical work.

A prepress professional validates the final file. This checklist only identifies what must be confirmed before delivery.
