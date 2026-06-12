#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Safrochain-Org/saflink-sdk.git}"
BRANCH="${BRANCH:-main}"

if [[ -d .git ]]; then
  echo "Git repository already initialized."
  exit 0
fi

git init -b "$BRANCH"
git add .
git commit -m "$(cat <<'EOF'
chore: initial SAFLink SDK documentation scaffold

Open-source specification and repository structure for the
@safrochain/saflink TypeScript client library.
EOF
)"

if [[ "${SET_REMOTE:-true}" == "true" ]]; then
  git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"
  echo "Remote origin set to $REPO_URL"
fi

echo "Done. Push with: git push -u origin $BRANCH"
