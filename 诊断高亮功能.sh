#!/bin/bash

# 诊断高亮功能问题

cd /www/wwwroot/feihub

echo "=== 1. 检查源代码是否包含高亮功能 ==="
if [ -f "src/utils/highlightKeyword.ts" ]; then
    echo "✅ highlightKeyword.ts 文件存在"
    grep -q "highlightKeyword" src/App.tsx && echo "✅ App.tsx 中已导入高亮功能" || echo "❌ App.tsx 中未找到高亮功能"
else
    echo "❌ highlightKeyword.ts 文件不存在"
fi

echo ""
echo "=== 2. 检查构建后的文件 ==="
if [ -f "dist/assets/index-*.js" ]; then
    JS_FILE=$(ls dist/assets/index-*.js | head -1)
    echo "构建后的 JS 文件: $JS_FILE"
    
    if grep -q "highlightKeyword\|renderHighlightedText" "$JS_FILE" 2>/dev/null; then
        echo "✅ 构建后的文件包含高亮功能"
    else
        echo "❌ 构建后的文件不包含高亮功能，需要重新构建"
    fi
else
    echo "❌ 未找到构建后的 JS 文件"
fi

echo ""
echo "=== 3. 检查 dist 目录 ==="
ls -lh dist/ 2>/dev/null | head -10

echo ""
echo "=== 4. 建议的修复步骤 ==="
echo "1. 清除浏览器缓存（Ctrl+Shift+R 或 Cmd+Shift+R）"
echo "2. 重新构建前端："
echo "   cd /www/wwwroot/feihub && npm run build"
echo "3. 检查构建后的文件是否包含高亮功能"
echo "4. 如果还是不行，检查浏览器控制台是否有错误"

