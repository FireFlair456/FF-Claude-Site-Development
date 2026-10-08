# FF Claude Site Development

This repo holds the code of the FireFlair prototype — the Claude artifact
"FireFlair — People. Events. Experiences."
(https://claude.ai/code/artifact/534f9590-a59f-434b-a21c-d9c46a586500).
Griffy and the other developers build the real Render site from it.

## Every publish is pushed here — no need to be asked

Whenever the FireFlair site artifact is published, its code goes to this repo
(main) in the same turn, with clear notes on what changed.

- Before publishing, write the notes for the developers to `.pending-notes.md`
  in this repo: a few plain bullets on what changed and why.
- Publish with a short, descriptive `label`.
- The PostToolUse hook in `.claude/settings.json` runs
  `scripts/sync-published-site.sh`, which saves the published file as the next
  point version, adds the notes to `CHANGELOG.md`, commits and pushes.
- If the hook didn't run (for example, this repo wasn't the working directory),
  do the same by hand: save the published file as the next version, update
  `CHANGELOG.md`, commit, push.

## Versions

- One file per version: `fireflair-vN.html`, then point releases
  `fireflair-vN.1.html`, `fireflair-vN.2.html` … for incremental updates.
- Whole numbers (v17, v18 …) only for an entirely new version, when Alex says so.
- The highest-numbered file is always the latest prototype.
- Saved files are the page itself: drop the artifact viewer's wrapper line if the
  published file carries one (the sync script does this).

## Never

- No prices, fees or costs in notes or changelog text.
