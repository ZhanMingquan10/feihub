#!/bin/bash

# 修复高亮功能

cd /www/wwwroot/feihub

echo "=== 第一步：修复 highlightKeyword.ts（添加 React 导入）==="

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
 */
export function highlightKeyword(text: string, keyword: string): HighlightResult {
  if (!keyword || !text) {
    return { text, parts: [{ text, highlight: false }] };
  }

  const keywords = keyword.trim().split(/\s+/).filter(k => k.length > 0).map(k => k.toLowerCase());
  if (keywords.length === 0) {
    return { text, parts: [{ text, highlight: false }] };
  }

  const regex = new RegExp(`(${keywords.map(k => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')})`, 'gi');
  const parts: Array<{ text: string; highlight: boolean }> = [];
  let lastIndex = 0;
  let match;

  while ((match = regex.exec(text)) !== null) {
    if (match.index > lastIndex) {
      parts.push({ text: text.substring(lastIndex, match.index), highlight: false });
    }
    parts.push({ text: match[0], highlight: true });
    lastIndex = match.index + match[0].length;
  }

  if (lastIndex < text.length) {
    parts.push({ text: text.substring(lastIndex), highlight: false });
  }

  return { text, parts: parts.length > 0 ? parts : [{ text, highlight: false }] };
}

/**
 * 将高亮结果渲染为 React 元素
 */
export function renderHighlightedText(result: HighlightResult, isDarkMode: boolean): React.ReactNode {
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

echo "✅ highlightKeyword.ts 已修复"

echo ""
echo "=== 第二步：更新 App.tsx ==="

python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 检查是否已导入
has_import = any('highlightKeyword' in line for line in lines)

if not has_import:
    # 找到 ModalShell 导入的位置
    for i, line in enumerate(lines):
        if 'import { ModalShell }' in line:
            lines.insert(i + 1, 'import { highlightKeyword, renderHighlightedText } from "./utils/highlightKeyword";\n')
            break
    print("✅ 已添加导入语句")

# 更新标题（查找 {doc.title}）
for i, line in enumerate(lines):
    if '{doc.title}' in line and 'renderHighlightedText' not in line:
        lines[i] = line.replace(
            '{doc.title}',
            '{search ? renderHighlightedText(highlightKeyword(doc.title, search), isDarkMode) : doc.title}'
        )
        print("✅ 已更新标题高亮")
        break

# 更新预览内容（查找 {doc.preview || "暂无预览"}）
for i, line in enumerate(lines):
    if 'doc.preview || "暂无预览"' in line and 'renderHighlightedText' not in line:
        lines[i] = line.replace(
            '{doc.preview || "暂无预览"}',
            '{search && doc.preview ? renderHighlightedText(highlightKeyword(doc.preview, search), isDarkMode) : (doc.preview || "暂无预览")}'
        )
        print("✅ 已更新预览内容高亮")
        break

# 更新标签（查找 {tag} 在标签渲染中）
for i, line in enumerate(lines):
    if '{tag}' in line and 'doc.tags.map' in ''.join(lines[max(0, i-5):i]):
        # 检查是否已经更新过
        if 'tagHighlighted' not in ''.join(lines[max(0, i-10):i+5]):
            # 在标签 map 前添加变量定义
            for j in range(max(0, i-10), i):
                if 'doc.tags.map((tag) =>' in lines[j]:
                    # 在 map 后添加变量定义
                    indent = len(lines[j]) - len(lines[j].lstrip())
                    new_line = ' ' * indent + 'const tagHighlighted = search ? highlightKeyword(tag, search) : null;\n'
                    lines.insert(j + 1, new_line)
                    # 更新标签内容
                    lines[i] = line.replace(
                        '{tag}',
                        '{search && tagHighlighted ? renderHighlightedText(tagHighlighted, isDarkMode) : tag}'
                    )
                    print("✅ 已更新标签高亮")
                    break
        break

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ App.tsx 已更新")
PYEOF

echo ""
echo "=== 第三步：重新构建 ==="
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ 高亮功能已修复并构建完成！"
    echo ""
    echo "请清除浏览器缓存后测试："
    echo "  - Windows/Linux: Ctrl+Shift+R"
    echo "  - Mac: Cmd+Shift+R"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
fi

