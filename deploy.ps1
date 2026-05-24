# Spendwise 自動化部署腳本
# 執行方式：PowerShell 中執行
#   .\deploy.ps1

param(
    [string]$RepoUrl = ""
)

$ErrorActionPreference = "Stop"

# ============================================================
# 工具函式
# ============================================================

function Write-Step {
    param([string]$Number, [string]$Title)
    Write-Host ""
    Write-Host ("═" * 60) -ForegroundColor Cyan
    Write-Host "  STEP $Number`：$Title" -ForegroundColor Cyan
    Write-Host ("═" * 60) -ForegroundColor Cyan
}

function Write-SubStep {
    param([string]$Text)
    Write-Host "  ▶ $Text" -ForegroundColor Gray
}

function Write-Note {
    param([string]$Text)
    Write-Host "  📝 $Text" -ForegroundColor Yellow
}

function Ask-Input {
    param([string]$Prompt, [string]$Default = "")
    if ($Default) {
        $result = Read-Host "$Prompt (直接按 Enter 使用：`$Default`)"
        if ([string]::IsNullOrWhiteSpace($result)) { return $Default }
        return $result
    }
    return Read-Host "$Prompt"
}

function Open-Browser {
    param([string]$Url)
    Write-Host "  🌐 自動開啟瀏覽器：$Url" -ForegroundColor Green
    Start-Process $Url
    Start-Sleep -Seconds 2
}

# ============================================================
# 前置檢查
# ============================================================

$projectDir = "C:\Users\GM1.4_CT\Documents\Project\finance"
if (-not (Test-Path $projectDir)) {
    Write-Host "錯誤：找不到專案資料夾 $projectDir" -ForegroundColor Red
    exit 1
}

Set-Location $projectDir

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       Spendwise 自動化部署腳本                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan

# 檢查 Git
$headFile = Join-Path $projectDir ".git\HEAD"
if (-not (Test-Path $headFile)) {
    Write-Host "[初始化] 找不到 Git repo，正在初始化..." -ForegroundColor Yellow
    git init --initial-branch=main
    git config user.email "spendwise@example.com"
    git config user.name "Spendwise"
    Write-Host "Git 初始化完成" -ForegroundColor Green
} else {
    $test = git status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[修復] Git repo 損壞，正在重新建立..." -ForegroundColor Yellow
        cmd /c "rd /s /q `"$projectDir\.git`"" 2>$null
        Start-Sleep -Seconds 1
        git init --initial-branch=main
        git config user.email "spendwise@example.com"
        git config user.name "Spendwise"
    }
}

# 檢查是否有 commit
$hasCommits = git rev-parse HEAD 2>$null
if (-not $hasCommits) {
    git add .
    git commit -m "Initial commit: Spendwise accounting app" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "已建立初始 commit" -ForegroundColor Green
    }
} else {
    Write-Host "Git repo 正常，已有 commit" -ForegroundColor Green
}

# ============================================================
# STEP 1：建立 GitHub Repo
# ============================================================

Write-Step "1" "建立 GitHub Repo"

Write-Host ""
Write-Host "即將在瀏覽器開啟 GitHub 建立新 Repo 頁面" -ForegroundColor White
Write-Host "請在網頁上完成以下設定：" -ForegroundColor White
Write-Host ""
Write-Host "  1. Repository name 填入：spendwise" -ForegroundColor Gray
Write-Host "  2. 選擇：Public" -ForegroundColor Gray
Write-Host "  3. 不要勾選：Add a README 或其他任何選項" -ForegroundColor Gray
Write-Host "  4. 點擊：Create repository" -ForegroundColor Gray
Write-Host ""
Write-Host "建立完成後，複製頁面上「…or push an existing repository」區塊的" -ForegroundColor White
Write-Host "第二行指令中的網址，格式類似：" -ForegroundColor White
Write-Host "  https://github.com/USERNAME/spendwise.git" -ForegroundColor Gray
Write-Host ""

# 自動開啟瀏覽器
Open-Browser "https://github.com/new"

Write-Host ""
$githubUrl = Ask-Input "請貼上你的 GitHub Repo 網址"
if ([string]::IsNullOrWhiteSpace($githubUrl)) {
    Write-Host "錯誤：必須提供 GitHub Repo 網址" -ForegroundColor Red
    Write-Host "或複製並執行 GitHub 頁面上的指令：" -ForegroundColor Yellow
    exit 1
}

# 設定 remote 並 push
git remote remove origin 2>$null | Out-Null
git remote add origin $githubUrl
git branch -M main

Write-Host ""
Write-Host "正在推送程式碼到 GitHub..." -ForegroundColor Yellow
git push -u origin main --force 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 成功推送！Repo 已上線！" -ForegroundColor Green
} else {
    Write-Host "❌ 推送失敗。請手動執行以下指令：" -ForegroundColor Red
    Write-Host "  git push -u origin main" -ForegroundColor Gray
    Write-Host ""
    Write-Host "或許需要先在 GitHub 頁面點擊 'Code' > 'Push an existing repository'" -ForegroundColor Yellow
    $retry = Ask-Input "推送成功後直接按 Enter 繼續，如果失敗則輸入 'n' 離開"
    if ($retry -eq "n") { exit 1 }
}

# ============================================================
# STEP 2：部署到 Render
# ============================================================

Write-Step "2" "部署到 Render"

Write-Host ""
Write-Host "Render 網站會在瀏覽器開啟" -ForegroundColor White
Write-Host "請完成以下設定：" -ForegroundColor White
Write-Host ""
Write-Host "  1. 登入或註冊 Render 帳號（可用 GitHub 登入）" -ForegroundColor Gray
Write-Host "  2. 點擊：New > Web Service" -ForegroundColor Gray
Write-Host "  3. 在 'Connect a repository' 頁面找到你的 'spendwise' repo" -ForegroundColor Gray
Write-Host "  4. 點擊 'Connect'" -ForegroundColor Gray
Write-Host "  5. 設定以下內容：" -ForegroundColor Gray
Write-Host ""
Write-Host "     Name：           spendwise" -ForegroundColor White
Write-Host "     Region：         Singapore（或離你最近）" -ForegroundColor White
Write-Host "     Branch：         main" -ForegroundColor White
Write-Host "     Build Command： pip install -r requirements.txt" -ForegroundColor White
Write-Host "     Start Command： gunicorn -c gunicorn.conf.py app:create_app()" -ForegroundColor White
Write-Host ""
Write-Host "  6. 滾動到 'Environment' 區塊" -ForegroundColor Gray
Write-Host "  7. 點擊 'Add Environment Variable'" -ForegroundColor Gray
Write-Host "  8. Key 填：SECRET_KEY" -ForegroundColor White
Write-Host "     Value 填：spendwise-secret-key-$(Get-Random -Maximum 99999)" -ForegroundColor White
Write-Host "  9. Plan 選擇：Free" -ForegroundColor Gray
Write-Host " 10. 點擊：Create Web Service" -ForegroundColor Gray
Write-Host ""
Write-Host "建立後 Render 會開始 Build，稍等 1-3 分鐘..." -ForegroundColor Yellow
Write-Host ""

# 自動開啟 Render
Open-Browser "https://render.com"

Write-Host ""
Write-Host "請在 Render 頁面上完成上述設定並建立 Web Service" -ForegroundColor White
Write-Host "等到 Status 變成 'Live' 且出現藍色連結後，" -ForegroundColor White
Write-Host "複製該網址回來（格式：https://spendwise.onrender.com）" -ForegroundColor White
Write-Host ""

$deployUrl = Ask-Input "請貼上你的 Render 網址"
if ([string]::IsNullOrWhiteSpace($deployUrl)) {
    Write-Host "錯誤：必須提供 Render 網址才能測試" -ForegroundColor Red
    exit 1
}

# ============================================================
# STEP 3：測試部署結果
# ============================================================

Write-Step "3" "測試網站"

Write-Host ""
Write-Host "正在測試網站是否正常運作..." -ForegroundColor Yellow

# 測試登入頁
try {
    $loginPage = Invoke-WebRequest -Uri "$deployUrl/auth/login" -MaximumRedirection 5 -ErrorAction Stop
    if ($loginPage.StatusCode -eq 200) {
        Write-Host "✅ 登入頁讀取成功！" -ForegroundColor Green
    } else {
        Write-Host "⚠️  頁面狀態碼：$($loginPage.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ 無法讀取網站，錯誤：" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Gray
    Write-Host ""
    Write-Host "常見問題：" -ForegroundColor Yellow
    Write-Host "  - Build 是否成功？Render Dashboard 查看 logs" -ForegroundColor Gray
    Write-Host "  - 是否還在 Build 中？等待 Status 變成 Live" -ForegroundColor Gray
    Write-Host "  - 稍等 30 秒後再試一次" -ForegroundColor Gray
}

# ============================================================
# 完成
# ============================================================

Write-Host ""
Write-Host ("╔" + ("═" * 58) + "╗") -ForegroundColor Cyan
Write-Host ("║" + (" " * 58) + "║") -ForegroundColor Cyan
Write-Host -NoNewline "║" -ForegroundColor Cyan
Write-Host (" Deploy Complete!".PadRight(59) + "║") -ForegroundColor Green
Write-Host -NoNewline "║" -ForegroundColor Cyan
Write-Host ("  你的網站：$deployUrl".PadRight(59) + "║") -ForegroundColor White
Write-Host -NoNewline "║" -ForegroundColor Cyan
Write-Host ("  首次使用：先去註冊一個帳號".PadRight(59) + "║") -ForegroundColor Gray
Write-Host ("║" + (" " * 58) + "║") -ForegroundColor Cyan
Write-Host ("╚" + ("═" * 58) + "╝") -ForegroundColor Cyan
Write-Host ""

# 開啟網站
Open-Browser $deployUrl

Write-Host ""
Write-Host "已自動在瀏覽器開啟你的網站！" -ForegroundColor Green
Write-Host "開始記帳吧！💰" -ForegroundColor Green