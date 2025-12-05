#!/bin/bash

# 优化爬虫 - 精确定位中间内容区域（简化版）
# 根据截图，排除：左上角标题栏、右上角登录按钮、左侧导航栏、右下角按钮

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：保存当前版本 ==="
if [ -f "版本管理系统.sh" ]; then
    bash 版本管理系统.sh save "优化前版本（准备精确定位中间内容）" 2>/dev/null || echo "⚠️  版本管理系统未安装，跳过"
else
    echo "⚠️  版本管理系统未安装，跳过"
fi

echo ""
echo "=== 第二步：优化内容提取逻辑 ==="

# 创建备份
cp feishu-puppeteer.ts feishu-puppeteer.ts.bak_optimize_middle

python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. 优化选择器数组 - 在 selectors 数组开头添加精确选择器
for i, line in enumerate(lines):
    if 'const selectors = [' in line:
        # 找到数组结束位置
        j = i + 1
        while j < len(lines) and '];' not in lines[j]:
            j += 1
        
        # 检查是否已经优化过
        if any('.page-main.docx-width-mode' in lines[k] for k in range(i, j+1)):
            print("⚠️  选择器已经优化过，跳过")
            break
        
        # 在数组开头添加精确选择器
        indent = len(line) - len(line.lstrip())
        indent_str = ' ' * indent
        
        new_selectors = [
            f"{indent_str}  // 精确选择器：优先匹配中间内容区域（排除导航、标题栏、按钮）\n",
            f"{indent_str}  '.page-main.docx-width-mode', // 主要内容区域\n",
            f"{indent_str}  '.page-main-item.editor', // 编辑器区域\n",
            f"{indent_str}  '.page-block.root-block', // 页面块\n",
            f"{indent_str}  '.page-block-children', // 页面块内容\n",
            f"{indent_str}  'main .app-main.main__content:not(.catalogue__main):not(.catalogue__main-wrapper)', // 主内容区域（排除目录）\n",
            f"{indent_str}  'main .app-main.main__content', // 主内容区域（备用）\n",
            f"{indent_str}  // 通用选择器（备用）\n",
        ]
        
        lines.insert(i+1, ''.join(new_selectors))
        print(f"✅ 在选择器数组中添加精确选择器（第 {i+1} 行后）")
        break

# 2. 优化排除元素列表 - 在 unwanted 选择器中添加更多排除项
for i, line in enumerate(lines):
    if 'const unwanted = clone.querySelectorAll' in line or 'clone.querySelectorAll' in line:
        # 找到选择器字符串结束位置
        j = i
        quote_char = None
        if '`' in line:
            quote_char = '`'
        elif "'" in line:
            quote_char = "'"
        elif '"' in line:
            quote_char = '"'
        
        if quote_char:
            # 查找结束的引号
            start_quote = line.find(quote_char)
            if start_quote >= 0:
                # 在同一行或后续行查找结束引号
                content_start = start_quote + 1
                quote_count = 1
                k = i
                pos = content_start
                
                while k < len(lines) and quote_count > 0:
                    if k == i:
                        text = line[pos:]
                    else:
                        text = lines[k]
                        pos = 0
                    
                    for char in text:
                        if char == quote_char:
                            quote_count -= 1
                            if quote_count == 0:
                                break
                        pos += 1
                    
                    if quote_count > 0:
                        k += 1
                        pos = 0
                
                # 检查是否已经包含新的排除项
                existing_content = ''.join(lines[i:k+1])
                if 'catalogue' in existing_content and 'login' in existing_content:
                    print("⚠️  排除元素列表已经优化过，跳过")
                    break
                
                # 在结束引号前添加新的排除项
                end_line_idx = k
                end_pos = pos - 1
                
                # 在结束引号前插入新的排除项
                if end_line_idx == i:
                    # 在同一行
                    before = lines[i][:end_pos]
                    after = lines[i][end_pos:]
                    new_excludes = '''
                // 根据截图，排除以下元素：
                aside, .catalogue, .catalogue__main, .catalogue__main-wrapper, // 左侧导航栏（目录）
                .left-content, .right-content, // 左右侧边栏
                [class*="login"], [class*="Login"], // 右上角登录按钮
                [class*="help"], [class*="Help"], [class*="guide"], [class*="Guide"], // 帮助中心
                [class*="shortcut"], [class*="Shortcut"], [class*="Shortcuts"], // 快捷键按钮
                [class*="comment"], [class*="Comment"], [class*="查看全文"], // 评论相关
                button, .button, [role="button"], // 所有按钮
                [class*="action"], [class*="Action"], // 操作按钮
                [aria-label*="Help"], [aria-label*="help"], [aria-label*="帮助"], // 帮助相关
                [aria-label*="登录"], [aria-label*="Login"], [aria-label*="注册"], // 登录注册
                '''
                    lines[i] = before + new_excludes + after
                    print(f"✅ 在排除元素列表中添加新项（第 {i+1} 行）")
                break

# 3. 优化验证逻辑 - 添加更严格的文本验证
for i, line in enumerate(lines):
    if '验证内容：排除导航栏和帮助中心' in line or '验证内容：排除导航栏' in line:
        # 查找验证的 if 语句
        j = i
        while j < len(lines) and j < i + 10:
            if 'text.includes' in lines[j] and 'Help Center' in lines[j]:
                # 检查是否已经包含新的验证
                if '帮助中心' in ''.join(lines[i:j+5]):
                    print("⚠️  验证逻辑已经优化过，跳过")
                    break
                
                # 在验证条件中添加更多检查
                # 找到 if 语句的结束位置
                k = j
                paren_count = 0
                found_open = False
                while k < len(lines) and k < j + 15:
                    for char in lines[k]:
                        if char == '(':
                            paren_count += 1
                            found_open = True
                        elif char == ')':
                            paren_count -= 1
                            if found_open and paren_count == 0:
                                # 在结束括号前添加新的验证条件
                                indent = len(lines[k]) - len(lines[k].lstrip())
                                indent_str = ' ' * indent
                                
                                new_checks = f''' ||
                  text.includes('帮助中心') ||
                  text.includes('快捷键') ||
                  text.includes('登录') ||
                  text.includes('注册') ||
                  text.includes('Login') ||
                  text.includes('Sign Up') ||
                  text.includes('查看全文') ||
                  text.includes('评论') ||
                  // 检查是否主要是导航内容（开头包含目录结构）
                  (text.substring(0, 200).match(/^[一二三四五六七八九十]+[、\\.]/) && text.length < 500)'''
                                
                                # 在 ) 前插入
                                lines[k] = lines[k].replace(')', new_checks + '\n' + indent_str + ')', 1)
                                print(f"✅ 在验证逻辑中添加新检查（第 {k+1} 行）")
                                break
                    if paren_count == 0 and found_open:
                        break
                    k += 1
                break
        break

# 保存修改
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 优化完成")
print("")
print("主要优化：")
print("1. ✅ 优先选择中间内容区域的选择器")
print("2. ✅ 排除左侧导航栏、顶部标题栏、右上角登录按钮、底部按钮")
print("3. ✅ 添加更严格的文本验证")
PYEOF

echo ""
echo "=== 第三步：验证修改 ==="
echo "检查选择器优化："
grep -A 3 "精确选择器：优先匹配中间内容区域" feishu-puppeteer.ts | head -8

echo ""
echo "=== 第四步：重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 优化完成！"
    echo ""
    echo "测试建议："
    echo "  测试链接: https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb"
    echo "  查看日志: pm2 logs feihub-backend --lines 50"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
    echo "如果构建失败，可以恢复："
    echo "  cd /www/wwwroot/feihub/backend/src/lib"
    echo "  cp feishu-puppeteer.ts.bak_optimize_middle feishu-puppeteer.ts"
fi

