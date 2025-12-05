#!/bin/bash

echo "=========================================="
echo "  同步线上版本到 GitHub"
echo "=========================================="
echo ""

cd /www/wwwroot/feihub

# 1. 检查 Git 状态
echo "[1/5] 检查 Git 状态..."
if [ ! -d ".git" ]; then
    echo "❌ 未初始化 Git 仓库"
    echo "初始化 Git 仓库..."
    git init
    git remote add origin https://github.com/ZhanMingquan/feihub.git 2>/dev/null || echo "远程仓库已存在"
fi

# 2. 检查是否有未提交的更改
echo "[2/5] 检查更改..."
git status --short

# 3. 添加所有更改
echo "[3/5] 添加所有更改..."
git add .

# 4. 提交更改
echo "[4/5] 提交更改..."
COMMIT_MSG="同步线上版本 - $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG" || echo "没有更改需要提交"

# 5. 推送到 GitHub
echo "[5/5] 推送到 GitHub..."
echo "⚠️  注意：需要配置 GitHub 认证"
echo ""
echo "如果推送失败，请执行："
echo "  git push -u origin main"
echo "  或"
echo "  git push -u origin master"
echo ""

# 尝试推送
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
git push -u origin "$CURRENT_BRANCH" 2>&1 | head -20

echo ""
echo "=========================================="
echo "  ✅ 同步完成！"
echo "=========================================="
echo ""
echo "如果推送失败，请检查："
echo "1. GitHub 认证配置"
echo "2. 远程仓库地址是否正确"
echo "3. 分支名称是否正确"
echo ""

