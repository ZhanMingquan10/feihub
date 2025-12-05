#!/bin/bash
# 检查并修复分享按钮滚动折叠特效

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    content = f.read()

print("=== 检查当前代码状态 ===")

# 检查 isScrolled 状态
scrolled_count = content.count('const [isScrolled, setIsScrolled]')
print(f"isScrolled 状态出现次数: {scrolled_count}")

# 检查滚动监听
listener_count = content.count('handleScrollForButton')
print(f"handleScrollForButton 出现次数: {listener_count}")

# 检查分享按钮
if 'isScrolled ? "px-3 py-3 w-12 h-12' in content:
    print("✅ 分享按钮已使用 isScrolled")
else:
    print("❌ 分享按钮未使用 isScrolled")
    # 查找分享按钮的实际代码
    button_match = re.search(r'<button[^>]*分享文档[^<]*</button>', content, re.DOTALL)
    if button_match:
        print(f"找到分享按钮代码（前100字符）: {button_match.group(0)[:100]}")

# 查找分享按钮的位置
lines = content.split('\n')
for i, line in enumerate(lines):
    if '分享文档' in line and '<button' in ''.join(lines[max(0, i-10):i+1]):
        print(f"\n分享按钮在第 {i+1} 行附近")
        print(f"按钮开始: {i-5} 到 {i+5}")
        for j in range(max(0, i-5), min(i+5, len(lines))):
            print(f"  {j+1}: {lines[j][:80]}")
        break

PYEOF

