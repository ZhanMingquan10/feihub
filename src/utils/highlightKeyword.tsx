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


