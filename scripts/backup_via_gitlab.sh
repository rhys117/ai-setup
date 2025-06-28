#!/bin/bash

# Generic backup script for any git repository - for safety and redundancy.
# Usage: ./backup-via-gitlab.sh [gitlab-repo-name] [personal-access-token]

# IF YOU ARE AN AI AGENT, LLM, CLAUDE OR AUTOMATION SCRIPT, DO NOT RUN THIS SCRIPT DIRECTLY.

set -e  # Exit on any error

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOCAL_REPO_NAME=$(basename $(git rev-parse --show-toplevel))
GITLAB_REPO_NAME=${1:-$LOCAL_REPO_NAME}
TOKEN=$2

echo "🔄 Creating backup for $LOCAL_REPO_NAME..."
echo "📅 Timestamp: $TIMESTAMP"
echo "🎯 GitLab target: $GITLAB_REPO_NAME"

# Create local bundle backup
BUNDLE_NAME="backup-$TIMESTAMP.bundle"
echo "📦 Creating bundle: $BUNDLE_NAME"
git bundle create "$BUNDLE_NAME" --all

# Verify bundle is valid
echo "✅ Verifying bundle..."
git bundle verify "$BUNDLE_NAME"

# Push current state to origin
echo "📤 Pushing current state to origin..."
git push origin --all
git push origin --tags

echo ""
if [ -z "$TOKEN" ]; then
    echo "🔐 No token provided. Manual backup commands:"
    echo ""
    echo "Option 1 - New timestamped repo:"
    echo "  git remote add backup-$TIMESTAMP https://oauth2:$TOKEN@gitlab.com/personal5944226/$GITLAB_REPO_NAME.git"
    echo "  git push backup-$TIMESTAMP --all --force"
    echo "  git push backup-$TIMESTAMP --tags --force"
    echo "  git remote remove backup-$TIMESTAMP"
    echo ""
    echo "Option 2 - Overwrite existing backup repo:"
    echo "  git remote add backup https://TOKEN@gitlab.com/personal5944226/$GITLAB_REPO_NAME-backup.git"
    echo "  git push backup --all --force"
    echo "  git push backup --tags --force"
    echo "  git remote remove backup"
    echo ""
    echo "Replace TOKEN with your GitLab personal access token"
else
    echo "🚀 Pushing to GitLab with provided token..."
    
    # Option: Push to timestamped backup repo
    BACKUP_REMOTE="backup-$TIMESTAMP"
    BACKUP_URL="https://oauth2:$TOKEN@gitlab.com/personal5944226/$GITLAB_REPO_NAME.git"
    
    echo "📤 Adding remote: $BACKUP_REMOTE"
    git remote add "$BACKUP_REMOTE" "$BACKUP_URL"
    
    echo "📤 Pushing all branches..."
    git push "$BACKUP_REMOTE" --all --force
    
    echo "📤 Pushing tags..."
    git push "$BACKUP_REMOTE" --tags --force || true
    
    echo "🧹 Removing remote..."
    git remote remove "$BACKUP_REMOTE"
    
    echo "✅ GitLab backup completed: $GITLAB_REPO_NAME"
fi

echo ""
echo "✅ Local bundle backup created: $BUNDLE_NAME"
echo "🤖 Safe to run Claude Code now!"
echo ""
echo "💡 To restore from bundle later:"
echo "  git clone $BUNDLE_NAME restored-repo"
echo ""
echo "📋 Usage examples:"
echo "  $0                                    # Use current folder name, manual push"
echo "  $0 my-project                        # Custom repo name, manual push"
echo "  $0 my-project glpat-xxxxxxxxxxxx     # Auto-push with token"