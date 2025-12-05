#!/bin/bash

# 安装版本管理系统

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：创建版本管理系统 ==="

cat > 版本管理系统.sh << 'VERSION_EOF'
#!/bin/bash

VERSION_DIR="/www/wwwroot/feihub/backend/src/lib/versions"
FILE_NAME="feishu-puppeteer.ts"
TARGET_FILE="/www/wwwroot/feihub/backend/src/lib/${FILE_NAME}"

mkdir -p "$VERSION_DIR"

show_help() {
    echo "=== 版本管理系统 ==="
    echo "用法: $0 [命令] [参数]"
    echo "命令: save [描述] | list | restore [版本号] | current | diff [版本号]"
}

save_version() {
    local description="$1"
    if [ -z "$description" ]; then
        echo "❌ 请提供版本描述"
        exit 1
    fi
    
    if [ ! -f "$TARGET_FILE" ]; then
        echo "❌ 文件不存在: $TARGET_FILE"
        exit 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local version="v${timestamp}"
    local version_file="${VERSION_DIR}/${FILE_NAME}.${version}"
    
    cp "$TARGET_FILE" "$version_file"
    
    local info_file="${VERSION_DIR}/versions.txt"
    echo "${version}|${description}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$info_file"
    
    ln -sf "$version_file" "${VERSION_DIR}/${FILE_NAME}.latest"
    
    echo "✅ 版本已保存: $version"
    echo "   描述: $description"
}

list_versions() {
    local info_file="${VERSION_DIR}/versions.txt"
    if [ ! -f "$info_file" ]; then
        echo "⚠️  暂无版本记录"
        return
    fi
    
    echo "=== 版本列表 ==="
    printf "%-20s %-40s %-20s\n" "版本号" "描述" "保存时间"
    echo "--------------------------------------------------------------------------------"
    tac "$info_file" | while IFS='|' read -r version description timestamp; do
        printf "%-20s %-40s %-20s\n" "$version" "$description" "$timestamp"
    done
}

restore_version() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "❌ 请提供版本号"
        list_versions
        exit 1
    fi
    
    if [ "$version" = "latest" ]; then
        if [ -L "${VERSION_DIR}/${FILE_NAME}.latest" ]; then
            version=$(readlink -f "${VERSION_DIR}/${FILE_NAME}.latest" | xargs basename | sed "s/${FILE_NAME}\.//")
        else
            echo "❌ 未找到 latest 版本"
            exit 1
        fi
    fi
    
    local version_file="${VERSION_DIR}/${FILE_NAME}.${version}"
    
    if [ ! -f "$version_file" ]; then
        echo "❌ 版本不存在: $version"
        list_versions
        exit 1
    fi
    
    if [ -f "$TARGET_FILE" ]; then
        local backup_file="${TARGET_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
        cp "$TARGET_FILE" "$backup_file"
        echo "✅ 当前文件已备份到: $backup_file"
    fi
    
    cp "$version_file" "$TARGET_FILE"
    
    local info_file="${VERSION_DIR}/versions.txt"
    local version_info=$(grep "^${version}|" "$info_file" 2>/dev/null)
    
    echo "✅ 已恢复到版本: $version"
    if [ -n "$version_info" ]; then
        IFS='|' read -r v desc ts <<< "$version_info"
        echo "   描述: $desc"
        echo "   时间: $ts"
    fi
    echo ""
    echo "⚠️  请手动执行: cd /www/wwwroot/feihub/backend && npm run build && pm2 restart feihub-backend"
}

show_current() {
    echo "=== 当前版本信息 ==="
    echo "文件: $TARGET_FILE"
    
    if [ ! -f "$TARGET_FILE" ]; then
        echo "❌ 文件不存在"
        exit 1
    fi
    
    local file_size=$(stat -c%s "$TARGET_FILE" 2>/dev/null || stat -f%z "$TARGET_FILE" 2>/dev/null)
    local file_time=$(stat -c%y "$TARGET_FILE" 2>/dev/null || stat -f%Sm "$TARGET_FILE" 2>/dev/null)
    
    echo "大小: $file_size 字节"
    echo "修改时间: $file_time"
}

diff_version() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "❌ 请提供版本号"
        exit 1
    fi
    
    local version_file="${VERSION_DIR}/${FILE_NAME}.${version}"
    
    if [ ! -f "$version_file" ]; then
        echo "❌ 版本不存在: $version"
        exit 1
    fi
    
    echo "=== 版本对比 ==="
    if command -v diff >/dev/null 2>&1; then
        diff -u "$version_file" "$TARGET_FILE" | head -100
    else
        echo "⚠️  diff 命令不可用"
    fi
}

case "$1" in
    save)
        save_version "$2"
        ;;
    list)
        list_versions
        ;;
    restore)
        restore_version "$2"
        ;;
    current)
        show_current
        ;;
    diff)
        diff_version "$2"
        ;;
    *)
        show_help
        ;;
esac
VERSION_EOF

chmod +x 版本管理系统.sh

echo "✅ 版本管理系统已创建"
echo ""
echo "=== 第二步：保存当前版本 ==="
bash 版本管理系统.sh save "回退后的稳定版本（未优化滚动）"

echo ""
echo "=== 第三步：查看版本列表 ==="
bash 版本管理系统.sh list

echo ""
echo "✅✅✅ 版本管理系统安装完成！"
echo ""
echo "使用方法:"
echo "  bash 版本管理系统.sh save \"版本描述\"    # 保存版本"
echo "  bash 版本管理系统.sh list                  # 查看所有版本"
echo "  bash 版本管理系统.sh restore [版本号]      # 恢复到指定版本"
echo "  bash 版本管理系统.sh current               # 查看当前版本"

