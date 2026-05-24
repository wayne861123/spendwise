# Spendwise GitHub Repo Setup Script
# Usage: Run in PowerShell:
#   .\setup.ps1

$ErrorActionPreference = "Continue"
$projectDir = "C:\Users\GM1.4_CT\Documents\Project\finance"

if (-not (Test-Path $projectDir)) {
    Write-Host "ERROR: Project folder not found" -ForegroundColor Red
    exit 1
}

Set-Location $projectDir

# 0. Check if .git\HEAD exists
$headFile = Join-Path $projectDir ".git\HEAD"

if (-not (Test-Path $headFile)) {
    Write-Host "[0/5] No Git repo found, creating one..." -ForegroundColor Yellow
    git init --initial-branch=main
    git config user.email "spendwise@example.com"
    git config user.name "Spendwise"
    Write-Host "Git initialized!" -ForegroundColor Green
} else {
    # Try running git status to see if it actually works
    $testResult = git status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[0/5] .git folder exists but is broken. Re-creating..." -ForegroundColor Yellow

        # Try to remove it
        $gitDir = Join-Path $projectDir ".git"
        Write-Host "  Attempting to remove .git..." -ForegroundColor Gray

        # Use cmd rmdir (most reliable for locked dirs)
        cmd /c "rd /s /q `"$gitDir`"" 2>$null

        if (-not (Test-Path (Join-Path $projectDir ".git\HEAD"))) {
            Write-Host "  .git removed successfully" -ForegroundColor Green
        } else {
            Write-Host "  .git removal failed. Let us try harder..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2

            # Try removing files one by one
            Get-ChildItem -Path $gitDir -Recurse -Force -ErrorAction SilentlyContinue |
                Sort-Object { $_.FullName.Length } -Descending |
                ForEach-Object {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                }
            Remove-Item $gitDir -Force -Recurse -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1

            if (-not (Test-Path (Join-Path $projectDir ".git"))) {
                Write-Host "  .git removed" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "========================================" -ForegroundColor Red
                Write-Host "MANUAL STEP NEEDED" -ForegroundColor Red
                Write-Host "========================================" -ForegroundColor Red
                Write-Host ""
                Write-Host "The .git folder is locked by another process." -ForegroundColor White
                Write-Host "Please do these steps manually:" -ForegroundColor White
                Write-Host ""
                Write-Host "  1. Close ALL programs (VS Code, Terminal, Explorer)" -ForegroundColor Yellow
                Write-Host "  2. Open a NEW PowerShell window" -ForegroundColor Yellow
                Write-Host "  3. Run these commands:" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "     cd C:\Users\GM1.4_CT\Documents\Project\finance" -ForegroundColor Gray
                Write-Host "     Remove-Item .git -Recurse -Force" -ForegroundColor Gray
                Write-Host "     git init --initial-branch=main" -ForegroundColor Gray
                Write-Host "     git config user.email `"spendwise@example.com`"" -ForegroundColor Gray
                Write-Host "     git config user.name `"Spendwise`"" -ForegroundColor Gray
                Write-Host "     git add ." -ForegroundColor Gray
                Write-Host "     git commit -m `"Initial commit`"" -ForegroundColor Gray
                exit 1
            }
        }

        # Re-init git
        git init --initial-branch=main
        git config user.email "spendwise@example.com"
        git config user.name "Spendwise"
        Write-Host "Git re-initialized!" -ForegroundColor Green
    } else {
        Write-Host "[0/5] Git repo is working, skipping" -ForegroundColor Yellow
    }
}

# 1. Stage all files
Write-Host "[1/5] Staging files..." -ForegroundColor Green
git add .
$staged = git diff --cached --name-only 2>&1
if ($LASTEXITCODE -eq 0 -and $staged) {
    Write-Host "Staged $($staged.Count) file(s)" -ForegroundColor Green
} else {
    Write-Host "Nothing new to stage" -ForegroundColor Yellow
}

# 2. gh CLI check
$ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
$manual = $false

if ($ghAvailable) {
    Write-Host "[2/5] Creating GitHub Repo with gh CLI..." -ForegroundColor Green
    $result = gh repo create spendwise --public --source=. --push 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Repo created and pushed!" -ForegroundColor Green
    } else {
        Write-Host "WARNING: gh failed." -ForegroundColor Yellow
        $manual = $true
    }
} else {
    Write-Host "[2/5] gh CLI not found." -ForegroundColor Yellow
    $manual = $true
}

# 3. Commit
Write-Host "[3/5] Committing..." -ForegroundColor Green
$commitResult = git commit -m "Initial commit: Spendwise accounting app" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Commit done!" -ForegroundColor Green
} else {
    Write-Host "Already committed" -ForegroundColor Yellow
}

# 4. Instructions
Write-Host "[4/5] Done!" -ForegroundColor Green

if ($manual) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "NEXT STEPS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Step 1: Open https://github.com/new in your browser" -ForegroundColor White
    Write-Host "        Create repo named 'spendwise' (set to Public)" -ForegroundColor White
    Write-Host "        Do NOT add README or .gitignore" -ForegroundColor White
    Write-Host ""
    Write-Host "Step 2: Back in PowerShell, run:" -ForegroundColor White
    Write-Host ""
    Write-Host "  git remote add origin https://github.com/YOUR_USERNAME/spendwise.git" -ForegroundColor Gray
    Write-Host "  git push -u origin main" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 3: Deploy on Render:" -ForegroundColor White
    Write-Host "  - https://render.com > New > Web Service" -ForegroundColor White
    Write-Host "  - Connect your GitHub account > select 'spendwise'" -ForegroundColor White
    Write-Host "  - Name: spendwise" -ForegroundColor White
    Write-Host "  - Build Command: pip install -r requirements.txt" -ForegroundColor White
    Write-Host "  - Start Command: gunicorn -c gunicorn.conf.py app:create_app()" -ForegroundColor White
    Write-Host "  - Environment: SECRET_KEY = any-random-string" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS! Repo is live on GitHub!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Go to https://render.com > New > Web Service and deploy!" -ForegroundColor White
}

Write-Host "[5/5] Complete!" -ForegroundColor Green