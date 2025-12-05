@echo off
chcp 65001 >nul
title Reprocess Document
color 0A
cls
echo.
echo ========================================
echo   重新处理文档
echo ========================================
echo.
echo 此脚本将：
echo 1. 删除旧的文档记录
echo 2. 删除旧的提交记录
echo 3. 然后你可以重新提交文档链接
echo.
echo 注意：这将删除所有现有文档！
echo.
pause

cd /d "%~dp0"

echo [1] 删除 Document 表记录...
docker exec feihub-postgres psql -U feihub -d feihub -c "DELETE FROM \"Document\";"
echo.

echo [2] 删除 DocumentSubmission 表记录...
docker exec feihub-postgres psql -U feihub -d feihub -c "DELETE FROM \"DocumentSubmission\";"
echo.

echo ========================================
echo   清理完成！
echo ========================================
echo.
echo 现在可以重新提交文档链接了
echo 改进后的爬取逻辑会正确提取标题、作者和内容
echo.
pause


