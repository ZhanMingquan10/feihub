#!/bin/bash
# 验证服务器上的版本是否包含所有最新修改

cd /www/wwwroot/feihub

echo "=== 验证服务器版本 ==="
echo ""

# 1. 检查文件是否存在
echo "📁 检查文件..."
if [ -f "src/App.tsx" ]; then
    echo "✅ src/App.tsx 存在"
    APP_SIZE=$(wc -c < src/App.tsx)
    APP_LINES=$(wc -l < src/App.tsx)
    echo "   文件大小: $APP_SIZE 字节"
    echo "   文件行数: $APP_LINES 行"
else
    echo "❌ src/App.tsx 不存在"
    exit 1
fi

if [ -f "src/utils/highlightKeyword.ts" ]; then
    echo "✅ src/utils/highlightKeyword.ts 存在"
else
    echo "❌ src/utils/highlightKeyword.ts 不存在"
fi

echo ""

# 2. 检查关键功能
echo "🔍 检查关键功能..."

# 滚动折叠功能
if grep -q "const \[isScrolled, setIsScrolled\]" src/App.tsx; then
    echo "✅ isScrolled 状态已定义"
else
    echo "❌ isScrolled 状态缺失"
fi

if grep -q "handleScrollForButton" src/App.tsx; then
    echo "✅ 滚动监听函数存在"
else
    echo "❌ 滚动监听函数缺失"
fi

if grep -q "isScrolled.*px-3 py-3 w-12 h-12" src/App.tsx; then
    echo "✅ 分享按钮滚动折叠样式存在"
else
    echo "❌ 分享按钮滚动折叠样式缺失"
fi

# AI速读位置优化
if grep -q "right-1 top-1 md:-right-14 md:-top-4" src/App.tsx; then
    echo "✅ AI速读位置优化存在（移动端右上角）"
else
    echo "❌ AI速读位置优化缺失"
fi

if grep -q "text-\[7px\] md:text-xs" src/App.tsx; then
    echo "✅ AI速读字体大小优化存在"
else
    echo "❌ AI速读字体大小优化缺失"
fi

# 关键词高亮功能
if grep -q "highlightKeyword" src/App.tsx; then
    echo "✅ 关键词高亮功能存在"
else
    echo "❌ 关键词高亮功能缺失"
fi

if grep -q "renderHighlightedText" src/App.tsx; then
    echo "✅ 高亮文本渲染函数存在"
else
    echo "❌ 高亮文本渲染函数缺失"
fi

# 移动端优化
if grep -q "md:gap-6\|md:px-3\|md:py-1\.5" src/App.tsx; then
    echo "✅ 移动端响应式样式存在"
else
    echo "⚠️  移动端响应式样式可能不完整"
fi

# 浅色模式优化
if grep -q "bg-gray-200\|from-gray-100 via-gray-50" src/App.tsx; then
    echo "✅ 浅色模式背景优化存在"
else
    echo "⚠️  浅色模式背景可能未优化"
fi

# Share2 图标（如果已修改）
if grep -q "Share2" src/App.tsx; then
    echo "✅ Share2 图标已使用"
elif grep -q "Upload.*分享文档" src/App.tsx; then
    echo "⚠️  仍使用 Upload 图标（可考虑改为 Share2）"
fi

echo ""

# 3. 检查导入
echo "📦 检查导入..."
if grep -q "from.*highlightKeyword" src/App.tsx; then
    echo "✅ highlightKeyword 已导入"
else
    echo "❌ highlightKeyword 未导入"
fi

if grep -q "import.*Share2\|import.*Upload" src/App.tsx; then
    echo "✅ 图标已导入"
else
    echo "❌ 图标未导入"
fi

echo ""

# 4. 尝试构建
echo "🔨 尝试构建..."
if npm run build 2>&1 | tee /tmp/build_output.txt; then
    echo ""
    echo "✅✅✅ 构建成功！"
    echo ""
    echo "=== 构建输出摘要 ==="
    tail -20 /tmp/build_output.txt
else
    echo ""
    echo "❌ 构建失败，请查看错误信息："
    tail -30 /tmp/build_output.txt
    exit 1
fi

echo ""
echo "=== 验证完成 ==="
echo "如果所有检查都通过 ✅，说明版本已是最新的！"

