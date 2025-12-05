#!/bin/bash
# 完整恢复最新版本到服务器
# 使用方法：在服务器上执行此脚本

cd /www/wwwroot/feihub

echo "=== 完整恢复最新版本 ==="

# 步骤1: 确保目录存在
mkdir -p src/utils

# 步骤2: 创建 highlightKeyword.ts
cat > src/utils/highlightKeyword.ts << 'EOF'
/**
 * 高亮关键词工具函数
 * 在文本中高亮显示匹配的关键词
 */

import React from "react";
import clsx from "clsx";

export interface HighlightResult {
  text: string;
  parts: Array<{ text: string; highlight: boolean }>;
}

/**
 * 高亮文本中的关键词
 * @param text 原始文本
 * @param keyword 关键词（支持多个关键词，用空格分隔）
 * @returns 高亮后的结果
 */
export function highlightKeyword(text: string, keyword: string): HighlightResult {
  if (!keyword || !text) {
    return {
      text,
      parts: [{ text, highlight: false }]
    };
  }

  // 将关键词按空格分割，支持多个关键词
  const keywords = keyword
    .trim()
    .split(/\s+/)
    .filter(k => k.length > 0)
    .map(k => k.toLowerCase());

  if (keywords.length === 0) {
    return {
      text,
      parts: [{ text, highlight: false }]
    };
  }

  // 转义正则表达式特殊字符
  function escapeRegExp(str: string): string {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  // 创建正则表达式，匹配所有关键词（不区分大小写）
  const regex = new RegExp(`(${keywords.map(k => escapeRegExp(k)).join('|')})`, 'gi');
  
  const parts: Array<{ text: string; highlight: boolean }> = [];
  let lastIndex = 0;
  let match;

  // 使用正则表达式查找所有匹配
  while ((match = regex.exec(text)) !== null) {
    // 添加匹配前的文本
    if (match.index > lastIndex) {
      parts.push({
        text: text.substring(lastIndex, match.index),
        highlight: false
      });
    }

    // 添加匹配的关键词
    parts.push({
      text: match[0],
      highlight: true
    });

    lastIndex = match.index + match[0].length;
  }

  // 添加剩余的文本
  if (lastIndex < text.length) {
    parts.push({
      text: text.substring(lastIndex),
      highlight: false
    });
  }

  return {
    text,
    parts: parts.length > 0 ? parts : [{ text, highlight: false }]
  };
}

/**
 * 将高亮结果渲染为 React 元素
 */
export function renderHighlightedText(
  result: HighlightResult,
  isDarkMode: boolean
): React.ReactNode {
  return result.parts.map((part, index) => {
    if (part.highlight) {
      return React.createElement(
        'mark',
        {
          key: index,
          className: clsx(
            "px-0.5 rounded",
            isDarkMode
              ? "bg-yellow-500/30 text-yellow-200 font-medium"
              : "bg-yellow-300/60 text-yellow-900 font-medium"
          )
        },
        part.text
      );
    }
    return React.createElement('span', { key: index }, part.text);
  });
}
EOF

echo "✅ highlightKeyword.ts 已创建"

# 步骤3: 提示用户复制 App.tsx
echo ""
echo "⚠️  重要：请将本地 src/App.tsx 复制到服务器"
echo "方法1（推荐）：使用 scp 命令"
echo "  在本地执行: scp src/App.tsx root@服务器IP:/www/wwwroot/feihub/src/App.tsx"
echo ""
echo "方法2：使用宝塔面板文件管理器"
echo "  1. 在本地打开 src/App.tsx，全选复制"
echo "  2. 在服务器宝塔面板中打开 /www/wwwroot/feihub/src/App.tsx"
echo "  3. 全选替换内容"
echo ""
echo "方法3：使用以下命令在服务器上直接编辑（需要手动粘贴内容）"
echo "  nano /www/wwwroot/feihub/src/App.tsx"
echo ""
echo "等待 10 秒后继续..."
sleep 10

# 步骤4: 验证文件是否存在
if [ -f "src/App.tsx" ]; then
    echo "✅ App.tsx 已存在"
    
    # 检查关键内容
    if grep -q "isScrolled" src/App.tsx && grep -q "handleScrollForButton" src/App.tsx; then
        echo "✅ App.tsx 包含滚动折叠功能"
    else
        echo "⚠️  App.tsx 可能缺少滚动折叠功能，请检查"
    fi
    
    if grep -q "right-1 top-1 md:-right-14" src/App.tsx; then
        echo "✅ App.tsx 包含 AI速读 位置优化"
    else
        echo "⚠️  App.tsx 可能缺少 AI速读 位置优化，请检查"
    fi
    
    # 构建
    echo ""
    echo "=== 开始构建 ==="
    npm run build
    
    if [ $? -eq 0 ]; then
        echo "✅✅✅ 构建成功！"
    else
        echo "❌ 构建失败，请检查错误信息"
        exit 1
    fi
else
    echo "❌ App.tsx 不存在，请先复制文件"
    exit 1
fi

