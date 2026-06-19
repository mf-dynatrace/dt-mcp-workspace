#!/usr/bin/env bash
# setup.sh — First-run initialization for dt-mcp-workspace
# Creates local reference files from templates and validates .env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 dt-mcp-workspace — First-Run Setup"
echo "======================================="
echo ""

# --- 1. Initialize reference files from templates ---
echo "📄 Initializing reference files..."
initialized=0
skipped=0

for template in reference/*.template.md; do
  [ -f "$template" ] || continue
  target="${template%.template.md}.md"
  if [ -f "$target" ]; then
    skipped=$((skipped + 1))
  else
    cp "$template" "$target"
    initialized=$((initialized + 1))
    echo "   ✅ Created $(basename "$target")"
  fi
done

if [ "$initialized" -eq 0 ]; then
  echo "   ℹ️  All reference files already exist ($skipped skipped)"
else
  echo "   ✅ Initialized $initialized reference file(s), $skipped already existed"
fi
echo ""

# --- 1b. Initialize custom-instructions.md from template ---
if [ -f custom-instructions.md ]; then
  echo "📝 custom-instructions.md already exists (keeping your customizations)"
else
  if [ -f custom-instructions.template.md ]; then
    cp custom-instructions.template.md custom-instructions.md
    echo "📝 Created custom-instructions.md from template"
    echo "   ℹ️  Edit this file to add tenant-specific instructions"
  fi
fi
echo ""

# --- 2. Check .env ---
if [ -f .env ]; then
  echo "🔑 .env file found"
  # Check required variables (without displaying values)
  missing=0
  for var in DT_ENVIRONMENT DT_PLATFORM_TOKEN; do
    if ! grep -q "^${var}=" .env 2>/dev/null || [ -z "$(grep "^${var}=" .env | cut -d= -f2-)" ]; then
      echo "   ⚠️  $var is missing or empty in .env"
      missing=$((missing + 1))
    fi
  done
  if [ "$missing" -eq 0 ]; then
    echo "   ✅ Required variables configured"
  else
    echo "   ⚠️  $missing required variable(s) need to be set"
  fi
else
  echo "⚠️  No .env file found. Creating from template..."
  if [ -f .env.example ]; then
    cp .env.example .env
    echo "   ✅ Created .env from .env.example"
    echo "   ⚠️  Edit .env with your Dynatrace credentials before starting"
  else
    echo "   ❌ .env.example not found — create .env manually"
  fi
fi
echo ""

# --- 3. Check Node.js ---
if command -v node &>/dev/null; then
  node_version=$(node --version)
  echo "✅ Node.js $node_version found"
else
  echo "❌ Node.js not found — install Node.js 18+ from https://nodejs.org"
fi
echo ""

# --- 4. Create report directory ---
if [ ! -d report ]; then
  mkdir -p report
  echo "📁 Created report/ directory"
else
  echo "📁 report/ directory exists"
fi
echo ""

echo "======================================="
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit .env with your Dynatrace credentials (if not done)"
echo "  2. Open in VS Code: code ."
echo "  3. Or start Claude Code: claude"
echo "  4. Ask: \"What Dynatrace environment am I connected to?\""
echo ""
