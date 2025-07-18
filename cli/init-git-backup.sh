#!/bin/bash

# -----------------------------------------
# init-git-backup.sh – Initialize Git & Push to GitHub
# -----------------------------------------

REPO_URL="https://github.com/Bonapic/bonapic-v101.git"  # <-- Replace with your GitHub repo URL
BRANCH="main"

cd "$(dirname "$0")/.." || exit 1  # Go to project root (bonapic-v101)

echo "🔍 Checking if this directory is already a Git repository..."
if [ -d ".git" ]; then
  echo "✅ This is already a Git repository. Pulling latest changes..."
  git pull origin $BRANCH
else
  echo "🚀 Initializing new Git repository..."
  git init
  git add .
  git commit -m "Initial commit – full dev environment"
  git branch -M $BRANCH
  git remote add origin "$REPO_URL"
  echo "🌐 Pushing initial commit to GitHub..."
  git push -u origin $BRANCH
fi

echo "📦 Backing up all files..."
git add .
git commit -m "Automated backup on $(date +'%Y-%m-%d %H:%M:%S')" || echo "ℹ️ Nothing new to commit."
git push origin $BRANCH

echo "✅ Backup completed. GitHub repo is synced."
