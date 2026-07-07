#!/usr/bin/env bash
# auto-pull-setup.sh — macOS/Linux folder-open sync with dependency preflight
# Run via tasks.json on folder open (Linux/macOS path)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

# --- 1. Dependency preflight ---
missing_deps=()

if ! command -v git &>/dev/null; then
  missing_deps+=("git")
fi

if ! command -v bash &>/dev/null; then
  missing_deps+=("bash")
fi

if [ ${#missing_deps[@]} -gt 0 ]; then
  echo ""
  echo "❌ Missing required dependencies: ${missing_deps[*]}"
  echo ""
  echo "Installation guidance:"
  for dep in "${missing_deps[@]}"; do
    case "$dep" in
      git)
        echo "  git  → macOS: brew install git  |  Ubuntu/Debian: sudo apt install git"
        ;;
      bash)
        echo "  bash → macOS: brew install bash  |  Ubuntu/Debian: sudo apt install bash"
        ;;
    esac
  done
  echo ""
  echo "After installing, reload this VS Code window (Ctrl+Shift+P → 'Developer: Reload Window')."
  echo ""
  exit 1
fi

# --- 2. Pull latest updates ---
echo "🔄 Pulling latest updates..."
if ! git pull --ff-only; then
  echo ""
  echo "❌ git pull --ff-only failed."
  echo ""
  echo "Resolution hints:"
  echo "  • You have local uncommitted changes: git stash, then retry."
  echo "  • You have a diverged branch: resolve manually and run 'git pull'."
  echo "  • No internet connection: check your network and retry."
  echo ""
  exit 1
fi

# --- 3. Run setup ---
echo ""
echo "⚙️  Running setup..."
exec bash setup.sh
