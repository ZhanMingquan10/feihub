@echo off
chcp 65001 >nul
title Detailed Diagnosis
color 0B
cls
echo.
echo ========================================
echo   详细诊断
echo ========================================
echo.

echo [1] 检查 Document 表记录数...
docker exec feihub-postgres psql -U feihub -d feihub -c "SELECT COUNT(*) as total FROM \"Document\";"
echo.

echo [2] 检查 DocumentSubmission 表（最近5条）...
docker exec feihub-postgres psql -U feihub -d feihub -c "SELECT id, link, status, error, \"createdAt\", \"updatedAt\" FROM \"DocumentSubmission\" ORDER BY \"createdAt\" DESC LIMIT 5;"
echo.

echo [3] 检查各状态的提交数量...
docker exec feihub-postgres psql -U feihub -d feihub -c "SELECT status, COUNT(*) as count FROM \"DocumentSubmission\" GROUP BY status;"
echo.

echo [4] 如果有失败的提交，查看错误信息...
docker exec feihub-postgres psql -U feihub -d feihub -c "SELECT link, status, error FROM \"DocumentSubmission\" WHERE status = 'failed' ORDER BY \"createdAt\" DESC LIMIT 3;"
echo.

echo ========================================
echo   诊断完成
echo ========================================
echo.
echo 请查看：
echo 1. Document 表是否有记录（应该是 0）
echo 2. DocumentSubmission 表的状态
echo    - pending: 等待处理
echo    - processing: 正在处理
echo    - completed: 处理完成
echo    - failed: 处理失败（查看 error 字段）
echo.
pause


