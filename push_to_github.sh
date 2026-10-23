#!/usr/bin/env bash
# ==============================================================================
# ReliefHub - GitHub Push Helper Script
# ==============================================================================
# Usage:
#   chmod +x push_to_github.sh
#   ./push_to_github.sh https://github.com/<your-username>/<your-repo-name>.git
# ==============================================================================

set -e

REPO_URL="$1"

if [ -z "$REPO_URL" ]; then
  echo "❌ Error: GitHub Repository URL required."
  echo "Usage: ./push_to_github.sh https://github.com/<your-username>/<your-repo-name>.git"
  echo "Or SSH: ./push_to_github.sh git@github.com:<your-username>/<your-repo-name>.git"
  exit 1
fi

echo "🚀 Preparing ReliefHub repository for GitHub..."

# Ensure git is initialized
if [ ! -d ".git" ]; then
  git init -b main
fi

# Ensure user config is present
if [ -z "$(git config user.name)" ]; then
  git config user.name "ReliefHub Deployer"
fi
if [ -z "$(git config user.email)" ]; then
  git config user.email "deploy@reliefhub.org"
fi

# Stage all files
git add .

# Create commit if there are staged changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  git commit -m "feat: Initial ReliefHub Flood Relief Operations Platform commit"
else
  echo "ℹ️ Working tree clean, nothing new to commit."
fi

# Set remote
if git remote | grep -q "^origin$"; then
  echo "Updating existing origin remote..."
  git remote set-url origin "$REPO_URL"
else
  echo "Adding origin remote..."
  git remote add origin "$REPO_URL"
fi

# Rename branch to main if needed
git branch -M main

echo "Pushing code to: $REPO_URL ..."
git push -u origin main

echo ""
echo "✅ Success! ReliefHub has been pushed to GitHub."
echo "Repository: $REPO_URL"
