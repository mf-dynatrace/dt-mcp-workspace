#!/usr/bin/env bash
# migrate-to-v3.sh — One-time migration for existing MCP-cleanDeploy clones
# Migrates to the new dt-mcp-workspace structure with auto-updating skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔄 dt-mcp-workspace — Migration from MCP-cleanDeploy"
echo "======================================================"
echo ""
echo "This script will:"
echo "  1. Back up your existing reference files (with all your cached data)"
echo "  2. Pull the latest repo structure"
echo "  3. Restore your reference files (now gitignored — safe from future pulls)"
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

# --- 3. Pull latest from remote ---
echo "⬇️  Pulling latest repo structure..."
if git pull --ff-only 2>/dev/null; then
  echo "   ✅ Pull successful"
else
  echo "   ⚠️  Fast-forward pull failed. Trying merge..."
  if git pull --no-rebase 2>/dev/null; then
    echo "   ✅ Pull with merge successful"
  else
    echo "   ❌ Pull failed — resolve conflicts manually, then re-run this script"
    exit 1
  fi
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
