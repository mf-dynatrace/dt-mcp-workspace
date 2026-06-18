#!/usr/bin/env bash
# migrate-to-v3.sh — One-time migration for existing MCP-cleanDeploy workspaces
# Handles both git-cloned repos AND folder-copied workspaces (no .git)
# Migrates to the new dt-mcp-workspace structure with auto-updating skills
set -euo pipefail

REPO_URL="https://github.com/mf-dynatrace/dt-mcp-workspace.git"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔄 dt-mcp-workspace — Migration from MCP-cleanDeploy"
echo "======================================================"
echo ""
echo "This script will:"
echo "  1. Back up your existing reference files and .env"
echo "  2. Connect to (or initialize) the dt-mcp-workspace repo"
echo "  3. Pull the latest structure (skills, prompts, instructions)"
echo "  4. Restore your reference files (now gitignored — safe from future pulls)"
echo ""

# --- 1. Back up reference files ---
BACKUP_DIR=".reference-backup-$(date +%Y%m%d-%H%M%S)"

if [ -d reference ]; then
  echo "📦 Backing up reference files to $BACKUP_DIR/"
  mkdir -p "$BACKUP_DIR"
  cp reference/*.md "$BACKUP_DIR/" 2>/dev/null || true
  file_count=$(ls -1 "$BACKUP_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "   ✅ Backed up $file_count file(s)"
else
  echo "⚠️  No reference/ directory found — nothing to back up"
  BACKUP_DIR=""
fi
echo ""

# --- 2. Back up .env ---
if [ -f .env ]; then
  cp .env ".env.backup-$(date +%Y%m%d-%H%M%S)"
  echo "🔑 Backed up .env"
else
  echo "⚠️  No .env found"
fi
echo ""

# --- 3. Connect to repo and pull ---
if [ -d .git ]; then
  # Already a git repo — update remote and pull
  current_remote=$(git remote get-url origin 2>/dev/null || echo "")
  if [ "$current_remote" != "$REPO_URL" ]; then
    echo "🔗 Updating remote origin to dt-mcp-workspace..."
    git remote set-url origin "$REPO_URL" 2>/dev/null || git remote add origin "$REPO_URL"
    echo "   ✅ Remote updated"
  fi
  echo ""

  echo "⬇️  Pulling latest repo structure..."
  if git fetch origin && git reset --hard origin/main; then
    git branch --set-upstream-to=origin/main main 2>/dev/null || true
    echo "   ✅ Pull successful"
  else
    echo "   ❌ Pull failed — check your network connection and try again"
    exit 1
  fi
else
  # Not a git repo — initialize and connect
  echo "📂 No .git directory found — initializing git repo..."
  git init
  git remote add origin "$REPO_URL"
  echo "   ✅ Git initialized"
  echo ""

  echo "⬇️  Fetching dt-mcp-workspace..."
  if git fetch origin; then
    echo "   ✅ Fetch successful"
  else
    echo "   ❌ Fetch failed — check your network connection and try again"
    exit 1
  fi

  echo "📥 Applying latest workspace structure..."
  git checkout origin/main -- . 2>/dev/null || true
  git checkout -b main 2>/dev/null || git checkout main 2>/dev/null || true
  git branch --set-upstream-to=origin/main main 2>/dev/null || true
  git reset origin/main 2>/dev/null || true
  echo "   ✅ Workspace updated"
fi
echo ""

# --- 4. Initialize reference files from templates ---
echo "📄 Initializing reference files from templates..."
for template in reference/*.template.md; do
  [ -f "$template" ] || continue
  target="${template%.template.md}.md"
  if [ ! -f "$target" ]; then
    cp "$template" "$target"
    echo "   ✅ Created $(basename "$target") from template"
  fi
done
echo ""

# --- 5. Restore backed-up reference files ---
if [ -n "${BACKUP_DIR:-}" ] && [ -d "$BACKUP_DIR" ]; then
  echo "♻️  Restoring your reference data..."
  restored=0
  for backup_file in "$BACKUP_DIR"/*.md; do
    [ -f "$backup_file" ] || continue
    filename="$(basename "$backup_file")"
    # Skip template files in the backup
    if [[ "$filename" == *.template.md ]]; then
      continue
    fi
    target="reference/$filename"
    cp "$backup_file" "$target"
    restored=$((restored + 1))
  done
  echo "   ✅ Restored $restored reference file(s)"
  echo "   📁 Backup kept at $BACKUP_DIR/ (safe to delete when verified)"
fi
echo ""

# --- 6. Create report directory ---
mkdir -p report

# --- 7. Run setup for anything else ---
if [ -f setup.sh ]; then
  echo "🔧 Running setup checks..."
  bash setup.sh 2>/dev/null | grep -E "^(✅|⚠️|❌)" || true
fi
echo ""

echo "======================================================"
echo "✅ Migration complete!"
echo ""
echo "What changed:"
echo "  • reference/*.md files are now gitignored (your data is safe from pulls)"
echo "  • reference/*.template.md files are tracked (clean starting templates)"
echo "  • VS Code will auto-pull updates when you open the workspace"
echo "  • Skills auto-sync from upstream weekly via GitHub Actions"
echo ""
echo "Your .env and reference data are preserved and will not be affected by future git pulls."
echo ""
