#!/bin/bash

# 在服务器上添加高亮功能

cd /www/wwwroot/feihub

echo "=== 第一步：创建高亮工具函数 ==="

# 创建 utils 目录（如果不存在）
mkdir -p src/utils

# 创建 highlightKeyword.ts 文件
cat > src/utils/highlightKeyword.ts << 'EOF'
/**
 * 高亮关键词工具函数
 * 在文本中高亮显示匹配的关键词
 */

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
 * 转义正则表达式特殊字符
 */
function escapeRegExp(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
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
      return (
        <mark
          key={index}
          className={clsx(
            "px-0.5 rounded",
            isDarkMode
              ? "bg-yellow-500/30 text-yellow-200 font-medium"
              : "bg-yellow-300/60 text-yellow-900 font-medium"
          )}
        >
          {part.text}
        </mark>
      );
    }
    return <span key={index}>{part.text}</span>;
  });
}
EOF

echo "✅ highlightKeyword.ts 文件已创建"

echo ""
echo "=== 第二步：更新 App.tsx ==="

# 检查 App.tsx 是否已包含导入
if ! grep -q "highlightKeyword" src/App.tsx; then
    # 在导入语句后添加高亮功能的导入
    sed -i '/import { ModalShell }/a import { highlightKeyword, renderHighlightedText } from "./utils/highlightKeyword";' src/App.tsx
    
    echo "✅ 已添加导入语句"
else
    echo "⚠️  导入语句已存在"
fi

# 更新标题部分
if ! grep -q "renderHighlightedText(highlightKeyword(doc.title" src/App.tsx; then
    sed -i 's|{doc.title}|{search ? renderHighlightedText(highlightKeyword(doc.title, search), isDarkMode) : doc.title}|g' src/App.tsx
    echo "✅ 已更新标题高亮"
fi

# 更新预览内容部分
if ! grep -q "renderHighlightedText(highlightKeyword(doc.preview" src/App.tsx; then
    sed -i 's|{doc.preview || "暂无预览"}|{search && doc.preview ? renderHighlightedText(highlightKeyword(doc.preview, search), isDarkMode) : (doc.preview || "暂无预览")}|g' src/App.tsx
    echo "✅ 已更新预览内容高亮"
fi

# 更新标签部分（需要更复杂的替换）
# 先检查标签部分
if ! grep -q "tagHighlighted" src/App.tsx; then
    # 查找标签渲染的部分并替换
    python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

# 查找标签渲染的部分
pattern = r'(doc\.tags\.map\(\(tag\) => \(\s*<span key=\{tag\} className=)'
replacement = r'''doc.tags.map((tag) => {
                    const tagHighlighted = search ? highlightKeyword(tag, search) : null;
                    return (
                      <span key={tag} className='''

if re.search(pattern, content):
    content = re.sub(pattern, replacement, content)
    
    # 更新标签内容部分
    content = re.sub(
        r'(\{tag\})',
        r'{search && tagHighlighted ? renderHighlightedText(tagHighlighted, isDarkMode) : tag}',
        content,
        count=1
    )
    
    # 添加闭合括号
    content = re.sub(
        r'(</span>\s*\)\s*\))',
        r'</span>\n                    );\n                  })',
        content
    )
    
    with open('src/App.tsx', 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ 已更新标签高亮")
else:
    print("⚠️  未找到标签渲染部分，可能需要手动更新")
PYEOF
fi

echo ""
echo "=== 第三步：重新构建 ==="
npm run build

echo ""
echo "✅✅✅ 高亮功能已添加并构建完成！"
echo ""
echo "请清除浏览器缓存后测试："
echo "  - Windows/Linux: Ctrl+Shift+R"
echo "  - Mac: Cmd+Shift+R"

