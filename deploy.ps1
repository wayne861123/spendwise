# Spendwise Automated Deployment Script
# Usage: PowerShell
#   .\deploy.ps1

$ErrorActionPreference = "Stop"

# ============================================================
# Utility Functions
# ============================================================

function Write-Step {
    param([string]$Number, [string]$Title)
    Write-Host ""
    Write-Host ("============================================================") -ForegroundColor Cyan
    Write-Host ("  STEP $Number - $Title") -ForegroundColor Cyan
    Write-Host ("============================================================") -ForegroundColor Cyan
}

function Write-SubStep {
    param([string]$Text)
    Write-Host ("  > $Text") -ForegroundColor Gray
}

function Open-Browser {
    param([string]$Url)
    Write-Host ("  [OPENING BROWSER] $Url") -ForegroundColor Green
    Start-Process $Url
    Start-Sleep -Seconds 2
}

function Ask-Input {
    param([string]$Prompt, [string]$Default = "")
    if ($Default) {
        $result = Read-Host "$Prompt (press Enter for: $Default)"
        if ([string]::IsNullOrWhiteSpace($result)) { return $Default }
        return $result
    }
    return Read-Host "$Prompt"
}

# ============================================================
# Pre-flight Checks
# ============================================================

$projectDir = "C:\Users\GM1.4_CT\Documents\Project\finance"
if (-not (Test-Path $projectDir)) {
    Write-Host "[ERROR] Project folder not found: $projectDir" -ForegroundColor Red
    exit 1
}

Set-Location $projectDir

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Spendwise Automated Deployment Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Check Git
$headFile = Join-Path $projectDir ".git\HEAD"
if (-not (Test-Path $headFile)) {
    Write-Host "[INIT] Git repo not found, initializing..." -ForegroundColor Yellow
    git init --initial-branch=main
    git config user.email "spendwise@example.com"
    git config user.name "Spendwise"
    Write-Host "[OK] Git initialized" -ForegroundColor Green
} else {
    $test = git status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FIX] Git repo is broken, re-initializing..." -ForegroundColor Yellow
        cmd /c "rd /s /q `"$projectDir\.git`"" 2>$null
        Start-Sleep -Seconds 1
        git init --initial-branch=main
        git config user.email "spendwise@example.com"
        git config user.name "Spendwise"
    }
}

# Check commit
$hasCommits = git rev-parse HEAD 2>$null
if (-not $hasCommits) {
    git add .
    git commit -m "Initial commit: Spendwise accounting app" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Initial commit created" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] Git repo is healthy, commit exists" -ForegroundColor Green
}

# ============================================================
# STEP 1: Create GitHub Repo
# ============================================================

Write-Step "1" "Create GitHub Repo"

Write-Host ""
Write-Host "The browser will open GitHub's new repo page." -ForegroundColor White
Write-Host "Please do the following on the page:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Repository name: spendwise" -ForegroundColor Gray
Write-Host "  2. Select: Public" -ForegroundColor Gray
Write-Host "  3. DO NOT check: Add a README or anything else" -ForegroundColor Gray
Write-Host "  4. Click: Create repository" -ForegroundColor Gray
Write-Host ""
Write-Host "After creation, look for the section that says:" -ForegroundColor White
Write-Host "  '...or push an existing repository from the command line'" -ForegroundColor Gray
Write-Host "Copy the URL from the second line (git remote add origin ...)" -ForegroundColor White
Write-Host "It should look like: https://github.com/USERNAME/spendwise.git" -ForegroundColor Gray
Write-Host ""

Open-Browser "https://github.com/new"

Write-Host ""
$githubUrl = Ask-Input "Paste your GitHub Repo URL here"
if ([string]::IsNullOrWhiteSpace($githubUrl)) {
    Write-Host "[ERROR] You must provide a GitHub Repo URL" -ForegroundColor Red
    Write-Host "After creating the repo, copy the URL from the GitHub page and paste it here." -ForegroundColor Yellow
    exit 1
}

# Set remote and push
$remotes = git remote 2>$null
if ($remotes -contains "origin") {
    git remote remove origin
}
git remote add origin $githubUrl
git branch -M main

# Check if gh CLI exists (handles auth automatically)
$ghAvailable = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghAvailable) {
    Write-Host ""
    Write-Host "[AUTH] GitHub requires authentication to push code." -ForegroundColor Yellow
    Write-Host "We will use a GitHub Personal Access Token (PAT)." -ForegroundColor White
    Write-Host ""
    Write-Host "Step 1: In the browser that opens, create a new PAT:" -ForegroundColor White
    Open-Browser "https://github.com/settings/tokens/new?scopes=repo&description=SpendwiseDeploy"
    Write-Host ""
    Write-Host "  On the page that opens:" -ForegroundColor Gray
    Write-Host "    - Note: SpendwiseDeploy" -ForegroundColor Gray
    Write-Host "    - Expiration: 30 days" -ForegroundColor Gray
    Write-Host "    - Select checkbox: repo (full control)" -ForegroundColor Gray
    Write-Host "    - Click 'Generate token'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Step 2: COPY the token shown on screen (only appears once!)" -ForegroundColor White
    Write-Host ""

    $token = Ask-Input "Paste your GitHub Personal Access Token here"
    if ([string]::IsNullOrWhiteSpace($token)) {
        Write-Host "[ERROR] Token is required to push code" -ForegroundColor Red
        exit 1
    }

    # Embed token into remote URL for authentication
    $authUrl = $githubUrl -replace "https://", "https://$token@"
    git remote set-url origin $authUrl

    Write-Host ""
    Write-Host "Pushing code to GitHub... " -NoNewline -ForegroundColor Yellow
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = "push -u origin main"
    $psi.WorkingDirectory = $projectDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null
    $proc.WaitForExit()
    $pushExit = $proc.ExitCode
} else {
    Write-Host ""
    Write-Host "Pushing code to GitHub... " -NoNewline -ForegroundColor Yellow
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = "push -u origin main"
    $psi.WorkingDirectory = $projectDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null
    $proc.WaitForExit()
    $pushExit = $proc.ExitCode
}

$isSuccess = ($pushExit -eq 0)

if ($isSuccess) {
    Write-Host "[OK] Successfully pushed to GitHub!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Push failed. Error details:" -ForegroundColor Red
    Write-Host $pushOut
    Write-Host ""
    $retry = Ask-Input "Fix the error above and press Enter to retry, or type 'n' to quit."
    if ($retry -eq "n") { exit 1 }
}

# ============================================================
# STEP 2: Deploy on Render
# ============================================================

Write-Step "2" "Deploy on Render"

Write-Host ""
Write-Host "The Render website will open in your browser." -ForegroundColor White
Write-Host "Please complete these steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Log in or sign up for Render (use GitHub login)" -ForegroundColor Gray
Write-Host "  2. Click: New > Web Service" -ForegroundColor Gray
Write-Host "  3. Find your 'spendwise' repo in the list and click 'Connect'" -ForegroundColor Gray
Write-Host "  4. Configure the following settings:" -ForegroundColor Gray
Write-Host ""
Write-Host "     Name:           spendwise" -ForegroundColor White
Write-Host "     Region:         Singapore (or closest to you)" -ForegroundColor White
Write-Host "     Branch:         main" -ForegroundColor White
Write-Host "     Build Command:  pip install -r requirements.txt" -ForegroundColor White
Write-Host "     Start Command:  gunicorn -c gunicorn.conf.py app:app
     Environment variables:
       - RENDER = true
       - SECRET_KEY = any-random-string" -ForegroundColor White
Write-Host ""
Write-Host "  5. Scroll down to 'Environment' section" -ForegroundColor Gray
Write-Host "  6. Click 'Add Environment Variable'" -ForegroundColor Gray
Write-Host "  7. For Key enter: SECRET_KEY" -ForegroundColor White
$randomKey = "spendwise-secret-$(Get-Random -Maximum 99999)"
Write-Host "     For Value enter: $randomKey" -ForegroundColor White
Write-Host "  8. Plan: select 'Free'" -ForegroundColor Gray
Write-Host "  9. Click: 'Create Web Service'" -ForegroundColor Gray
Write-Host ""
Write-Host "Render will start building. Wait 1-3 minutes until Status shows 'Live'." -ForegroundColor Yellow
Write-Host "Once it is live, a blue URL will appear (format: https://spendwise.onrender.com)" -ForegroundColor White
Write-Host ""

Open-Browser "https://render.com"

Write-Host ""
$deployUrl = Ask-Input "Paste your Render website URL here"
if ([string]::IsNullOrWhiteSpace($deployUrl)) {
    Write-Host "[ERROR] You must provide the Render URL to test the site" -ForegroundColor Red
    exit 1
}

# ============================================================
# STEP 3: Test
# ============================================================

Write-Step "3" "Test Deployment"

Write-Host ""
Write-Host "Testing if the website is working..." -ForegroundColor Yellow

try {
    $loginPage = Invoke-WebRequest -Uri "$deployUrl/auth/login" -MaximumRedirection 5 -ErrorAction Stop
    if ($loginPage.StatusCode -eq 200) {
        Write-Host "[OK] Login page loaded successfully!" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Page status code: $($loginPage.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] Cannot reach the website: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Is the build still in progress? Wait for 'Live' status" -ForegroundColor Gray
    Write-Host "  - Check Render Dashboard > spendwise > Logs for errors" -ForegroundColor Gray
    Write-Host "  - Try again in 30 seconds" -ForegroundColor Gray
}

# ============================================================
# Done
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  DEPLOY COMPLETE!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Your website: $deployUrl" -ForegroundColor White
Write-Host "  GitHub repo:  $githubUrl" -ForegroundColor White
Write-Host ""
Write-Host "  To get started: open the URL and register an account!" -ForegroundColor Gray
Write-Host ""

Open-Browser $deployUrl

Write-Host "Browser opened with your website. Happy accounting!" -ForegroundColor Green