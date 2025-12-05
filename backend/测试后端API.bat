@echo off
chcp 65001 >nul
title Test Backend API
color 0B
cls
echo.
echo ========================================
echo   测试后端 API
echo ========================================
echo.

echo [测试 1] 健康检查...
curl -s http://localhost:4000/health
echo.
echo.

echo [测试 2] 获取文档列表...
curl -s http://localhost:4000/api/documents
echo.
echo.

echo [测试 3] 获取统计信息...
curl -s http://localhost:4000/api/documents/stats/summary
echo.
echo.

echo ========================================
echo   测试完成
echo ========================================
echo.
echo 如果看到 JSON 响应，说明 API 正常
echo 如果看到错误，请检查后端服务是否运行
echo.
pause


