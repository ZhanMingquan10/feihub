# PowerShell 脚本：从本地推送到 GitHub

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  从本地推送到 GitHub" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 切换到项目目录
$projectPath = "D:\AI+CPS(只做一件事_做好一件事)\13.出海工具站\feihub"
Set-Location $projectPath

# 1. 检查 Git 状态
Write-Host "[1/5] 检查 Git 状态..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    Write-Host "初始化 Git 仓库..." -ForegroundColor Yellow
    git init
    git remote add origin https://github.com/ZhanMingquan/feihub.git
}

# 2. 检查远程仓库
Write-Host "[2/5] 检查远程仓库..." -ForegroundColor Yellow
git remote -v

# 3. 检查 .gitignore
Write-Host "[3/5] 检查 .gitignore..." -ForegroundColor Yellow
if (-not (Test-Path ".gitignore")) {
    @"
# 依赖
node_modules/
backend/node_modules/

# 构建输出
dist/
backend/dist/

# 环境变量
.env
backend/.env
*.env.local

# 日志
*.log
logs/
backend/logs/

# 临时文件
*.tmp
*.bak
.DS_Store

# IDE
.vscode/
.idea/
*.swp
*.swo

# 备份文件
*.bak*
*.backup
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8
    Write-Host "✅ 已创建 .gitignore" -ForegroundColor Green
}

# 4. 添加所有文件
Write-Host "[4/5] 添加所有文件..." -ForegroundColor Yellow
git add .

# 5. 提交并推送
Write-Host "[5/5] 提交并推送..." -ForegroundColor Yellow
$commitMsg = "统一版本：同步最新代码 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $commitMsg

# 检查当前分支
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    $currentBranch = "main"
    git checkout -b main
}

Write-Host ""
Write-Host "推送到 GitHub..." -ForegroundColor Yellow
Write-Host "分支: $currentBranch" -ForegroundColor Cyan
Write-Host ""

git push -u origin $currentBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  ✅ 推送成功！" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "  ⚠️  推送失败" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "可能的原因：" -ForegroundColor Yellow
    Write-Host "1. 需要 GitHub 认证（Personal Access Token 或 SSH）" -ForegroundColor Yellow
    Write-Host "2. 网络连接问题" -ForegroundColor Yellow
    Write-Host "3. 分支名称不匹配" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请手动执行：" -ForegroundColor Cyan
    Write-Host "  git push -u origin $currentBranch" -ForegroundColor White
}

