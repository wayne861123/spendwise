@echo off
chcp 65001 >nul
echo === Spendwise GitHub Repo 初始化 ===
echo.

cd /d "%~dp0"

REM 檢查 git 是否初始化
if not exist ".git" (
    echo [1/5] 初始化 Git repo...
    git init
    git config user.email "spendwise@example.com"
    git config user.name "Spendwise"
    git branch -M main
) else (
    echo [1/5] Git repo 已存在，略過
)

REM 暫存所有檔案
echo [2/5] 暫存所有檔案...
git add .

REM 首次 commit
echo [3/5] 建立初始 commit...
git commit -m "Initial commit: Spendwise accounting app"

REM 嘗試用 gh 建立 repo
where gh >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [4/5] 建立 GitHub Repo...
    gh repo create spendwise --public --source=. --push
    if %ERRORLEVEL% equ 0 (
        echo [完成] Repo 已建立並推送！
    ) else (
        echo [警告] gh 建立失敗，請手動建立後執行以下指令：
        echo   git remote add origin https://github.com/YOUR_USERNAME/spendwise.git
        echo   git branch -M main
        echo   git push -u origin main
    )
) else (
    echo [4/5] 找不到 gh CLI，需要手動建立 Repo
)

echo [5/5] 完成！

echo.
echo === 下一步 ===
echo 1. 前往 https://github.com/new 建立名為 spendwise 的 public repo
echo 2. 連結到本專案後，在本資料夾執行:
echo      git remote add origin https://github.com/YOUR_USERNAME/spendwise.git
echo      git branch -M main
echo      git push -u origin main
echo.
echo 3. 在 Render (https://render.com) 建立 Web Service:
echo    - Name: spendwise
echo    - Build Command: pip install -r requirements.txt
echo    - Start Command: gunicorn -c gunicorn.conf.py app:create_app()
echo    - Environment: 新增 SECRET_KEY
pause