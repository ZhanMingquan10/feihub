@echo off
chcp 65001 >nul
echo ========================================
echo   推送代码到 GitHub
echo ========================================
echo.

echo [1/3] 检查远程仓库...
git remote -v
if errorlevel 1 (
    echo 远程仓库不存在，正在添加...
    git remote add origin https://github.com/ZhanMingquan/feihub.git
) else (
    echo 远程仓库已存在，正在更新...
    git remote set-url origin https://github.com/ZhanMingquan/feihub.git
)

echo.
echo [2/3] 重命名分支为 main...
git branch -M main

echo.
echo [3/3] 推送代码到 GitHub...
echo.
echo 注意：如果提示输入用户名和密码，请使用：
echo - 用户名：ZhanMingquan
echo - 密码：使用 Personal Access Token（不是 GitHub 密码）
echo.
echo 如何生成 Token：
echo 1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
echo 2. 点击 "Generate new token"
echo 3. 勾选 repo 权限
echo 4. 生成后复制 Token（只显示一次）
echo.

git push -u origin main

if errorlevel 1 (
    echo.
    echo ========================================
    echo   推送失败
    echo ========================================
    echo.
    echo 可能的原因：
    echo 1. 需要配置 GitHub 认证（使用 Personal Access Token）
    echo 2. 网络问题
    echo.
    echo 如果使用 HTTPS 方式，可以尝试：
    echo 1. 使用 Personal Access Token 作为密码
    echo 2. 或者配置 SSH 密钥（更安全）
    echo.
) else (
    echo.
    echo ========================================
    echo   ✅ 推送成功！
    echo ========================================
    echo.
    echo 代码已成功推送到 GitHub！
    echo 仓库地址：https://github.com/ZhanMingquan/feihub
    echo.
    echo 现在可以在服务器上使用以下命令克隆代码：
    echo   git clone https://github.com/ZhanMingquan/feihub.git
    echo.
)

pause

