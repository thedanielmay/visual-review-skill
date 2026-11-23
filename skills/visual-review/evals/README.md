# Eval suite

This suite uses `claude plugin eval`, not the older `evals.json` format.

Each case supplies a small PDF with one planted defect: clipped text, overlapping text, or a runt last line. Graders read the report file the agent writes and assert that the planted defect is named. A `tool_used` grader checks that the skill fired. The default run also executes a no-plugin baseline arm, so the score shows what the skill adds.

Run the suite from the plugin root:

```
claude plugin eval . --scaffold --allow-tools Write "Bash(*)" --no-publish --trust-plugin
```

The scaffold script copies the fixture PDF into the empty run workspace. Bash is needed for `pdftoppm` and `pdfinfo`. Write is needed for `review.md`. Results go to `evals/results/` and are ignored by git.

To run one case during iteration:

```
claude plugin eval . --case clipping --runs 1 --ablation none --scaffold --allow-tools Write "Bash(*)" --no-publish --trust-plugin
```

The fixture PDFs are hand-built one-page files. They contain no project names or personal data.
