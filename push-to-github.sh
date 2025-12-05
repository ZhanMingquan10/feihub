#!/bin/bash

# GitHub推送脚本
# 请替换以下变量为你的实际信息
GITHUB_USERNAME="ZhanMingquan10"
REPO_NAME="feihub"

echo "=== 推送代码到GitHub ==="
echo "GitHub用户名: $GITHUB_USERNAME"
echo "仓库名: $REPO_NAME"
echo ""

# 检查是否已配置GitHub远程仓库
if ! git remote get-url origin 2>/dev/null; then
    echo "添加GitHub远程仓库..."
    git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git
fi

# 推送到GitHub
echo "推送到GitHub..."
git push -u origin main

echo ""
echo "✅ 代码已成功推送到GitHub!"
echo "GitHub仓库地址: https://github.com/$GITHUB_USERNAME/$REPO_NAME"