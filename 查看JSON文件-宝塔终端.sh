#!/bin/bash

# 在宝塔终端查看 JSON 文件

echo "=== 查找最新的 JSON 文件 ==="
LATEST_JSON=$(ls -t /tmp/feishu_extracted_*.json 2>/dev/null | head -1)

if [ -z "$LATEST_JSON" ]; then
    echo "❌ 未找到 JSON 文件"
    echo "请先运行测试脚本"
    exit 1
fi

echo "找到文件: $LATEST_JSON"
echo ""

echo "=== 选项 ==="
echo "1. 查看完整 JSON（格式化）"
echo "2. 查看 JSON 结构（只显示键）"
echo "3. 查看 bodyText 内容"
echo "4. 查看选择器结果"
echo "5. 查看滚动信息"
echo "6. 查看文本文件"
echo ""

read -p "请选择 (1-6): " choice

case $choice in
    1)
        echo "=== 完整 JSON（格式化）==="
        cat "$LATEST_JSON" | python3 -m json.tool | less
        ;;
    2)
        echo "=== JSON 结构 ==="
        cat "$LATEST_JSON" | python3 -c "import json, sys; data = json.load(sys.stdin); print(json.dumps({k: type(v).__name__ for k, v in data.items()}, indent=2, ensure_ascii=False))"
        ;;
    3)
        echo "=== bodyText 内容 ==="
        cat "$LATEST_JSON" | python3 -c "import json, sys; data = json.load(sys.stdin); print(data.get('bodyText', {}).get('content', '未找到'))" | less
        ;;
    4)
        echo "=== 选择器结果 ==="
        cat "$LATEST_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
selectors = data.get('selectors', [])
for i, item in enumerate(selectors, 1):
    print(f'--- 选择器 {i}: {item[\"selector\"]} [{item[\"index\"]}] ---')
    print(f'类名: {item[\"className\"]}')
    print(f'标签: {item[\"tagName\"]}')
    print(f'文本长度: {item[\"textLength\"]} 字符')
    print(f'前500字符: {item[\"text\"][:500]}')
    print('')
" | less
        ;;
    5)
        echo "=== 滚动信息 ==="
        cat "$LATEST_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
scroll = data.get('scrollInfo', {})
print(f'页面高度: {scroll.get(\"scrollHeight\", \"未知\")}px')
print(f'当前滚动位置: {scroll.get(\"scrollTop\", \"未知\")}px')
print(f'视口高度: {scroll.get(\"clientHeight\", \"未知\")}px')
print(f'文本长度: {scroll.get(\"textLength\", \"未知\")} 字符')
"
        ;;
    6)
        LATEST_TXT=$(ls -t /tmp/feishu_extracted_*.txt 2>/dev/null | head -1)
        if [ -z "$LATEST_TXT" ]; then
            echo "❌ 未找到文本文件"
        else
            echo "=== 文本文件内容 ==="
            cat "$LATEST_TXT" | less
        fi
        ;;
    *)
        echo "无效选择"
        ;;
esac

