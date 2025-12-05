@echo off
chcp 65001 >nul
title Check Database
color 0B
cls
echo.
echo ========================================
echo   检查数据库内容
echo ========================================
echo.

echo [1] 检查 Document 表...
docker exec feihub-postgres psql -U feihub -d feihub -c "SELECT COUNT(*) as total FROM \"Document\";"
echo.

echo [2] 查看最近的文档...
docker exec feihub-postgres psql -U feihub -d feihub -c "SELECT id, title, author, \"createdAt\" FROM \"Document\" ORDER BY \"createdAt\" DESC LIMIT 5;"
echo.

echo [3] 检查 DocumentSubmission 表...
docker exec feihub-postgres psql -U feihub -d feihub -c "SELECT id, link, status, error, \"createdAt\" FROM \"DocumentSubmission\" ORDER BY \"createdAt\" DESC LIMIT 5;"
echo.

echo ========================================
echo   检查完成
echo ========================================
echo.
echo 如果看到文档记录，说明数据库有数据
echo 如果 status 是 "pending" 或 "processing"，说明还在处理中
echo 如果 status 是 "failed"，查看 error 字段了解失败原因
echo.
pause


