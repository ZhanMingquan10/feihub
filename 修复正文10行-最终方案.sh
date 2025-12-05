#!/bin/bash

cd /www/wwwroot/feihub

echo "=== 备份原文件 ==="
cp src/App.tsx src/App.tsx.bak
echo "✅ 已备份"

echo ""
echo "=== 使用 Python 修改代码 ==="

python3 << 'PYEOF'
import re

file_path = 'src/App.tsx'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找包含 "doc.preview && doc.preview.length > 500" 的行
found = False
for i, line in enumerate(lines):
    if 'doc.preview && doc.preview.length > 500' in line:
        # 向前查找 <p> 标签的开始
        p_start = None
        for j in range(i, max(-1, i-10), -1):
            if '<p className={clsx("mt-4 text-sm leading-relaxed whitespace-pre-wrap"' in lines[j]:
                p_start = j
                break
        
        if p_start is not None:
            # 向后查找 </p> 标签的结束
            p_end = None
            for j in range(i, min(len(lines), i+5)):
                if '</p>' in lines[j]:
                    p_end = j
                    break
            
            if p_end is not None:
                # 替换整个 <p> 标签块
                new_p_tag = '              <p className={clsx("mt-4 text-sm leading-relaxed whitespace-pre-wrap overflow-hidden", isDarkMode ? "text-gray-300" : "text-gray-600")} style={{ display: \'-webkit-box\', WebkitLineClamp: 10, WebkitBoxOrient: \'vertical\' }}>\n'
                new_content = '                {doc.preview || "暂无预览"}\n'
                new_p_close = '              </p>\n'
                
                # 替换
                lines[p_start] = new_p_tag
                lines[i] = new_content
                # 删除中间的行（如果有）
                if p_end > i:
                    for j in range(i+1, p_end):
                        lines[j] = ''
                lines[p_end] = new_p_close
                
                found = True
                print(f"✅ 找到并修改了第 {p_start+1} 到 {p_end+1} 行")
                break

if not found:
    print("❌ 未找到需要修改的代码")
    print("请使用 nano 手动编辑（见修复正文10行-直接执行命令.md）")
    exit(1)

# 写入文件
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 代码修改成功")
PYEOF

if [ $? -eq 0 ]; then
    echo ""
    echo "=== 验证修改 ==="
    if grep -q "WebkitLineClamp" src/App.tsx; then
        echo "✅ 验证成功，找到 WebkitLineClamp"
        echo ""
        echo "=== 显示修改后的代码 ==="
        grep -A 2 "WebkitLineClamp" src/App.tsx | head -3
        
        echo ""
        echo "=== 重新构建前端 ==="
        npm run build
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ 构建成功！"
            echo ""
            echo "=== 重载 Nginx ==="
            nginx -s reload
            echo ""
            echo "✅✅✅ 完成！"
            echo ""
            echo "请清除浏览器缓存（Ctrl+Shift+R 或 Cmd+Shift+R）后刷新页面"
        else
            echo "❌ 构建失败，请检查错误信息"
        fi
    else
        echo "❌ 验证失败，WebkitLineClamp 未找到"
        echo "请使用 nano 手动编辑"
    fi
else
    echo ""
    echo "❌ Python 脚本执行失败"
    echo "请使用 nano 手动编辑（见修复正文10行-直接执行命令.md）"
fi

