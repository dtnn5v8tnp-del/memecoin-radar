#!/usr/bin/env bash
# Idempotent: validates data.json, commits it if changed, pushes to main. Needs GITHUB_TOKEN in env.
set -euo pipefail
cd "$(dirname "$0")"
REPO_URL="https://github.com/dtnn5v8tnp-del/memecoin-radar.git"
python3 -c "import json;json.load(open('data.json'))" || { echo "data.json is not valid JSON" >&2; exit 1; }
: "${GITHUB_TOKEN:?GITHUB_TOKEN not set}"
AUTH="Authorization: Basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 -w0)"
git remote get-url origin >/dev/null 2>&1 || git remote add origin "$REPO_URL"
git add data.json index.html publish.sh
if git diff --cached --quiet; then
  echo "No changes to publish."
else
  git -c user.name="Grok Bot" -c user.email="dtnn5v8tnp-del@users.noreply.github.com" commit -q -m "Update data $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Committed."
fi
# push only if local is ahead of (or differs from) remote main
git -c "http.extraheader=$AUTH" fetch -q origin main 2>/dev/null || true
if [ "$(git rev-parse HEAD)" != "$(git rev-parse --verify -q origin/main || echo none)" ]; then
  git -c "http.extraheader=$AUTH" push -q origin HEAD:main
  echo "Pushed."
else
  echo "Remote already up to date."
fi
