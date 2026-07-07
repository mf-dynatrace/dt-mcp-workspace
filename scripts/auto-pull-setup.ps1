# auto-pull-setup.ps1 — Windows folder-open sync with dependency preflight
# Run via tasks.json on folder open (Windows path)

$ErrorActionPreference = "Stop"

# --- 1. Dependency preflight ---
$missingDeps = @()

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $missingDeps += "git"
}

if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    $missingDeps += "bash"
}

if ($missingDeps.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Missing required dependencies: $($missingDeps -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "Installation guidance:" -ForegroundColor Yellow
    if ($missingDeps -contains "git") {
        Write-Host "  git  → https://git-scm.com/download/win  (includes Git Bash)" -ForegroundColor Yellow
    }
    if ($missingDeps -contains "bash") {
        Write-Host "  bash → Install Git for Windows (Git Bash) from https://git-scm.com/download/win" -ForegroundColor Yellow
        Write-Host "         or enable Windows Subsystem for Linux: wsl --install" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "After installing, reload this VS Code window (Ctrl+Shift+P → 'Developer: Reload Window')." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# --- 2. Pull latest updates ---
Write-Host "🔄 Pulling latest updates..."
$pullResult = git pull --ff-only 2>&1
$pullExit = $LASTEXITCODE

if ($pullExit -ne 0) {
    Write-Host ""
    Write-Host "❌ git pull --ff-only failed (exit $pullExit):" -ForegroundColor Red
    Write-Host $pullResult
    Write-Host ""
    Write-Host "Resolution hints:" -ForegroundColor Yellow
    Write-Host "  • You have local uncommitted changes: git stash, then retry." -ForegroundColor Yellow
    Write-Host "  • You have a diverged branch: resolve manually and run 'git pull'." -ForegroundColor Yellow
    Write-Host "  • No internet connection: check your network and retry." -ForegroundColor Yellow
    Write-Host ""
    exit $pullExit
}

Write-Host $pullResult

# --- 3. Run setup ---
Write-Host ""
Write-Host "⚙️  Running setup..."
bash setup.sh
exit $LASTEXITCODE
