#!/bin/bash

echo "=========================================="
echo "  统一版本：线上 → GitHub"
echo "=========================================="
echo ""

cd /www/wwwroot/feihub

# 1. 检查 Git 状态
echo "[1/6] 检查 Git 状态..."
if [ ! -d ".git" ]; then
    echo "初始化 Git 仓库..."
    git init
    git remote add origin https://github.com/ZhanMingquan/feihub.git 2>/dev/null || echo "远程仓库已存在"
fi

# 2. 检查当前分支
echo "[2/6] 检查分支..."
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
if [ -z "$CURRENT_BRANCH" ]; then
    git checkout -b main 2>/dev/null || git checkout -b master 2>/dev/null
    CURRENT_BRANCH=$(git branch --show-current)
fi
echo "当前分支: $CURRENT_BRANCH"

# 3. 创建 .gitignore（如果不存在）
echo "[3/6] 检查 .gitignore..."
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
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
EOF
    echo "✅ 已创建 .gitignore"
fi

# 4. 添加所有文件
echo "[4/6] 添加所有文件..."
git add .

# 5. 提交更改
echo "[5/6] 提交更改..."
COMMIT_MSG="统一版本：同步线上最新版本 - $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG" || echo "没有更改需要提交"

# 6. 推送到 GitHub
echo "[6/6] 推送到 GitHub..."
echo "⚠️  如果推送失败，请检查 GitHub 认证配置"
echo ""

# 尝试推送
if git push -u origin "$CURRENT_BRANCH" 2>&1; then
    echo ""
    echo "✅ 推送成功！"
else
    echo ""
    echo "⚠️  推送失败，请手动执行："
    echo "  git push -u origin $CURRENT_BRANCH"
    echo ""
    echo "如果提示需要认证，请配置："
    echo "  git config --global credential.helper store"
    echo "  或使用 Personal Access Token"
fi

echo ""
echo "=========================================="
echo "  ✅ 版本统一完成！"
echo "=========================================="
echo ""
echo "GitHub 仓库应该已更新为线上最新版本"
echo ""

