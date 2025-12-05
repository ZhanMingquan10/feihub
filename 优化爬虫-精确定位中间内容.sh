#!/bin/bash

# 优化爬虫 - 精确定位中间内容区域
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

python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 1. 优化选择器数组 - 优先选择中间内容区域
# 查找 const selectors = [ 的位置
selector_pattern = r'(const selectors = \[)(.*?)(\];)'
def replace_selectors(match):
    prefix = match.group(1)
    old_selectors = match.group(2)
    suffix = match.group(3)
    
    # 新的精确选择器（优先匹配中间内容区域）
    new_selectors = '''
          // 精确选择器：优先匹配中间内容区域（排除导航、标题栏、按钮）
          '.page-main.docx-width-mode', // 主要内容区域
          '.page-main-item.editor', // 编辑器区域
          '.page-block.root-block', // 页面块
          '.page-block-children', // 页面块内容
          'main .app-main.main__content:not(.catalogue__main):not(.catalogue__main-wrapper)', // 主内容区域（排除目录）
          'main .app-main.main__content', // 主内容区域（备用）
          // 通用选择器（备用）
          '.wiki-content',
          '.wiki-body',
          '.doc-content',
          '.doc-body',
          '[data-content]',
          'main article',
          'article .content',
          '.page-content',
          '[class*="content"]:not(.left-content):not(.right-content)', // 排除左右侧边栏
          '[class*="body"]:not(.suite-body)', // 排除suite-body（可能包含导航）
          '[class*="main"]:not(.catalogue__main):not(.catalogue__main-wrapper)' // 排除目录'''
    
    return prefix + new_selectors + suffix

content = re.sub(selector_pattern, replace_selectors, content, flags=re.DOTALL)

# 2. 在克隆元素后，添加更严格的排除逻辑
# 查找 clone.querySelectorAll 的位置，在移除不需要的元素时添加更多排除项
# 使用更灵活的匹配，因为代码格式可能不同
unwanted_patterns = [
    (r'(const unwanted = clone\.querySelectorAll\(`)(.*?)(`\);)', True),
    (r'(clone\.querySelectorAll\(`)(.*?)(`\);)', True),
]

for pattern, use_template in unwanted_patterns:
    if re.search(pattern, content, flags=re.DOTALL):
        def replace_unwanted(match):
            prefix = match.group(1)
            old_unwanted = match.group(2)
            suffix = match.group(3)
            
            # 检查是否已经包含新的排除项
            if 'catalogue' in old_unwanted and 'login' in old_unwanted:
                return match.group(0)  # 已经优化过，不重复
            
            # 新的排除列表（根据截图，排除所有不需要的部分）
            new_unwanted = '''
                script, style, iframe, noscript, nav, header, footer,
                .ad, .gtm, .header, .footer, .sidebar, .menu,
                h1, .title, .author, .user-name, .creator-name,
                [class*="header"], [class*="footer"], [class*="nav"],
                [class*="menu"], [class*="sidebar"], [class*="toolbar"],
                [class*="image"], [class*="attachment"], [class*="media"],
                [class*="comment"], [class*="Comment"], [class*="highlight"],
                [class*="Highlight"], [class*="annotation"], [class*="Annotation"],
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
                img, picture, video, audio // 媒体元素（可选，如果需要保留图片可以删除这行）'''
            
            return prefix + new_unwanted + suffix
        
        content = re.sub(unwanted_patterns[0][0], replace_unwanted, content, flags=re.DOTALL)
        break

# 3. 在提取文本后，添加额外的验证，确保不包含导航和按钮文本
# 查找 if (text.length > 200) 的位置，在验证部分添加更严格的检查
validation_pattern = r'(// 验证内容：排除导航栏和帮助中心\s+if \(text && \(\s+text\.includes\([\'"]Help Center[\'"]\) \|\|\s+text\.includes\([\'"]Keyboard Shortcuts[\'"]\) \|\|\s+text\.includes\([\'"]Token Limit[\'"]\) \|\|\s+text\.trim\(\)\.split\(/\\s\+/\)\.length < 10 \|\|\s+\(!/\[\\u4e00-\\u9fa5\]/\.test\(text\) && text\.length < 200\)\s+\)) \{'
def replace_validation(match):
    # 添加更严格的验证
    return '''// 验证内容：排除导航栏、标题栏、按钮和帮助中心
                if (text && (
                  text.includes('Help Center') ||
                  text.includes('Keyboard Shortcuts') ||
                  text.includes('Token Limit') ||
                  text.includes('帮助中心') ||
                  text.includes('快捷键') ||
                  text.includes('登录') ||
                  text.includes('注册') ||
                  text.includes('Login') ||
                  text.includes('Sign Up') ||
                  text.includes('查看全文') ||
                  text.includes('评论') ||
                  // 检查是否主要是导航内容（开头包含目录结构）
                  (text.substring(0, 200).match(/^[一二三四五六七八九十]+[、\.]/) && text.length < 500) ||
                  text.trim().split(/\\s+/).length < 10 ||
                  (!/[\\u4e00-\\u9fa5]/.test(text) && text.length < 200)
                )) {'''
    
content = re.sub(validation_pattern, replace_validation, content, flags=re.DOTALL)

# 4. 在 bodyText 提取时，也添加相同的排除逻辑
body_unwanted_pattern = r'(const unwanted = body\.querySelectorAll\([\'"]script, style, iframe, noscript, nav, header, footer, .sidebar, .menu)(.*?)([\'"]\);)'
def replace_body_unwanted(match):
    prefix = match.group(1)
    old_unwanted = match.group(2)
    suffix = match.group(3)
    
    new_unwanted = ''', aside, .catalogue, .catalogue__main, .catalogue__main-wrapper,
                .left-content, .right-content,
                [class*="login"], [class*="Login"],
                [class*="help"], [class*="Help"], [class*="guide"], [class*="Guide"],
                [class*="shortcut"], [class*="Shortcut"], [class*="Shortcuts"],
                [class*="comment"], [class*="Comment"], [class*="查看全文"],
                button, .button, [role="button"],
                [class*="action"], [class*="Action"],
                [aria-label*="Help"], [aria-label*="help"], [aria-label*="帮助"],
                [aria-label*="登录"], [aria-label*="Login"], [aria-label*="注册"],
                h1, .title, .author, .user-name, .creator-name,
                [class*="header"], [class*="footer"], [class*="nav"],
                [class*="menu"], [class*="sidebar"], [class*="toolbar"],
                [class*="image"], [class*="attachment"], [class*="media"],
                [class*="comment"], [class*="Comment"], [class*="highlight"],
                [class*="Highlight"], [class*="annotation"], [class*="Annotation"],
                img, picture, video, audio'''
    
    return prefix + new_unwanted + suffix

content = re.sub(body_unwanted_pattern, replace_body_unwanted, content, flags=re.DOTALL)

# 保存备份
with open('feishu-puppeteer.ts.bak_optimize_middle', 'w', encoding='utf-8') as f:
    f.write(original)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 优化完成")
print("")
print("主要优化：")
print("1. ✅ 优先选择中间内容区域的选择器（.page-main, .page-main-item.editor等）")
print("2. ✅ 排除左侧导航栏（.catalogue, .sidebar等）")
print("3. ✅ 排除顶部标题栏和右上角登录按钮")
print("4. ✅ 排除底部按钮（帮助中心、快捷键等）")
print("5. ✅ 添加更严格的文本验证，确保不包含导航和按钮文本")
PYEOF

echo ""
echo "=== 第三步：验证修改 ==="
echo "检查选择器优化："
grep -A 5 "精确选择器：优先匹配中间内容区域" feishu-puppeteer.ts | head -10

echo ""
echo "检查排除元素："
grep -A 3 "根据截图，排除以下元素" feishu-puppeteer.ts | head -10

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
