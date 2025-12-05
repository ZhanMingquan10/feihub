#!/bin/bash

cd /www/wwwroot/feihub && \
cp src/App.tsx src/App.tsx.bak && \
python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

# 替换 <p> 标签的 className
content = content.replace(
    '<p className={clsx("mt-4 text-sm leading-relaxed whitespace-pre-wrap", isDarkMode ? "text-gray-300" : "text-gray-600")}>',
    '<p className={clsx("mt-4 text-sm leading-relaxed whitespace-pre-wrap overflow-hidden", isDarkMode ? "text-gray-300" : "text-gray-600")} style={{ display: \'-webkit-box\', WebkitLineClamp: 10, WebkitBoxOrient: \'vertical\' }}>'
)

# 替换内容部分
content = content.replace(
    '{doc.preview && doc.preview.length > 500 ? `${doc.preview.slice(0, 500)}...` : (doc.preview || "暂无预览")}',
    '{doc.preview || "暂无预览"}'
)

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 修改成功")
PYEOF
grep -q "WebkitLineClamp" src/App.tsx && echo "✅ 验证成功" && npm run build && nginx -s reload && echo "✅✅✅ 完成！请清除浏览器缓存后刷新页面" || echo "❌ 修改失败，请使用 nano 手动编辑"

