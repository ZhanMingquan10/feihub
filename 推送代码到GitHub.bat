@echo off
chcp 65001 >nul
echo ========================================
echo 推送代码到 GitHub
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] 检查 Git 状态...
git status
echo.

echo [2/4] 添加所有更改...
git add .
echo.

echo [3/4] 提交更改...
git commit -m "修复日期提取问题：添加详细调试日志和日期元素查找"
echo.

echo [4/4] 推送到 GitHub...
git push origin main
echo.

echo ========================================
echo 完成！
echo ========================================
pause
