#!/usr/bin/env bash
# Sync the published FireFlair site to this repo.
#
# Runs as a Claude Code PostToolUse hook on the Artifact tool (see
# .claude/settings.json). When the FireFlair site artifact has just been
# published, it saves the published code as the next point version
# (fireflair-v16.html -> fireflair-v16.1.html -> fireflair-v16.2.html ...),
# adds an entry to CHANGELOG.md, commits and pushes to origin/main.
#
# Notes for the commit: if .pending-notes.md exists in the repo root, its
# text becomes the commit body and the changelog entry, and the file is then
# removed. Otherwise the publish label is used.
#
# Can also be run by hand:  scripts/sync-published-site.sh < hook-input.json
# DRY_RUN=1 does everything except commit and push.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_ID="534f9590-a59f-434b-a21c-d9c46a586500"   # claude.ai/code/artifact/<id>
ARTIFACT_SLUG="BHgRj4ZH1mWdMtf8heW82s"               # claude.ai/artifact/<slug>

input="$(cat)"
fail() { echo "FireFlair GitHub sync: $*" >&2; exit 2; }   # exit 2 = tell Claude

# Only a successful page publish of the FireFlair site counts.
action="$(jq -r '.tool_input.action // "publish"' <<<"$input" 2>/dev/null)"
[ "$action" = "publish" ] || exit 0
[ "$(jq -r '.tool_input.asset // false' <<<"$input" 2>/dev/null)" = "true" ] && exit 0
grep -q -e "$ARTIFACT_ID" -e "$ARTIFACT_SLUG" <<<"$input" || exit 0
grep -q "Published " <<<"$input" || exit 0

src="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
[ -n "$src" ] && [ -f "$src" ] || fail "published file not found ($src) — push it by hand."
label="$(jq -r '.tool_input.label // empty' <<<"$input")"
version_id="$(grep -o 'version id [0-9A-Za-z-]*' <<<"$input" | head -1 | awk '{print $3}')"

cd "$REPO" || fail "repo not found"
git fetch -q origin main && git rebase -q origin/main 2>/dev/null || git rebase --abort 2>/dev/null

# Next point version after the highest fireflair-vN(.M).html in the repo.
latest="$(ls fireflair-v*.html 2>/dev/null | sed -E 's/^fireflair-v([0-9]+)(\.([0-9]+))?\.html$/\1 \3 &/' \
  | awk '{ if (NF==2) { print $1, 0, $2 } else { print $1, $2, $3 } }' | sort -k1,1n -k2,2n | tail -1)"
[ -n "$latest" ] || fail "no fireflair-v*.html in the repo"
read -r major minor latest_file <<<"$latest"
next="v${major}.$((minor + 1))"
dest="fireflair-${next}.html"

# Save a clean copy: drop the viewer's own wrapper if the file carries one.
python3 - "$src" "$dest" <<'PY'
import sys
src, dest = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().split("\n")
if len(lines) > 2 and lines[0].startswith("<!doctype html><html><head><meta charset=utf8>") and lines[1].lower().startswith("<!doctype html>"):
    lines = lines[1:]
    while lines and lines[-1].strip() == "":
        lines.pop()
    if lines and lines[-1].strip() == "</body></html>":
        lines.pop()
    lines.append("")
open(dest, "w", encoding="utf-8").write("\n".join(lines))
PY

if cmp -s "$dest" "$latest_file"; then rm -f "$dest"; exit 0; fi   # nothing new

title="${label:-Published update}"
if [ -s .pending-notes.md ]; then notes="$(cat .pending-notes.md)"; else notes="- ${title}"; fi
today="$(date +%Y-%m-%d)"
{
  echo "## ${next} — ${today} — ${title}"
  [ -n "$version_id" ] && echo "Artifact version ${version_id} · file \`${dest}\`" || echo "File \`${dest}\`"
  echo
  echo "$notes" | grep -v -e '^Co-Authored-By:' -e '^Claude-Session:'
  echo
  [ -f CHANGELOG.md ] && tail -n +3 CHANGELOG.md
} > CHANGELOG.new
{ echo "# FireFlair prototype — changelog"; echo; cat CHANGELOG.new; } > CHANGELOG.md && rm -f CHANGELOG.new
rm -f .pending-notes.md

[ "${DRY_RUN:-0}" = "1" ] && { echo "DRY_RUN: would commit ${dest}"; exit 0; }

git add "$dest" CHANGELOG.md
git add -u .pending-notes.md 2>/dev/null || true
git commit -q -F - <<MSG || fail "commit failed"
FireFlair ${next}: ${title}

${notes}

Synced automatically when the site was published${version_id:+ (artifact version ${version_id})}.
MSG
for attempt in 1 2; do
  if timeout 120 git push -q origin HEAD:main; then echo "FireFlair GitHub sync: pushed ${dest}"; exit 0; fi
  git fetch -q origin main && git rebase -q origin/main
done
fail "committed ${dest} but the push failed — run: git -C \"$REPO\" push origin HEAD:main"
