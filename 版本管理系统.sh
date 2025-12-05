#!/bin/bash

# 版本管理系统

VERSION_DIR="/www/wwwroot/feihub/backend/src/lib/versions"
FILE_NAME="feishu-puppeteer.ts"
TARGET_FILE="/www/wwwroot/feihub/backend/src/lib/${FILE_NAME}"

# 创建版本目录
mkdir -p "$VERSION_DIR"

# 显示帮助信息
show_help() {
    echo "=== 版本管理系统 ==="
    echo ""
    echo "用法: $0 [命令] [参数]"
    echo ""
    echo "命令:"
    echo "  save [描述]      - 保存当前版本（带描述）"
    echo "  list             - 列出所有版本"
    echo "  restore [版本号] - 恢复到指定版本"
    echo "  current          - 显示当前版本信息"
    echo "  diff [版本号]    - 对比当前版本和指定版本的差异"
    echo ""
    echo "示例:"
    echo "  $0 save \"修复日期提取问题\""
    echo "  $0 list"
    echo "  $0 restore v1.0.0"
    echo "  $0 current"
}

# 保存版本
save_version() {
    local description="$1"
    if [ -z "$description" ]; then
        echo "❌ 请提供版本描述"
        echo "用法: $0 save \"版本描述\""
        exit 1
    fi
    
    if [ ! -f "$TARGET_FILE" ]; then
        echo "❌ 文件不存在: $TARGET_FILE"
        exit 1
    fi
    
    # 生成版本号（基于时间戳）
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local version="v${timestamp}"
    local version_file="${VERSION_DIR}/${FILE_NAME}.${version}"
    
    # 保存文件
    cp "$TARGET_FILE" "$version_file"
    
    # 保存版本信息
    local info_file="${VERSION_DIR}/versions.txt"
    echo "${version}|${description}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$info_file"
    
    # 创建符号链接指向最新版本
    ln -sf "$version_file" "${VERSION_DIR}/${FILE_NAME}.latest"
    
    echo "✅ 版本已保存: $version"
    echo "   描述: $description"
    echo "   文件: $version_file"
}

# 列出所有版本
list_versions() {
    local info_file="${VERSION_DIR}/versions.txt"
    if [ ! -f "$info_file" ]; then
        echo "⚠️  暂无版本记录"
        return
    fi
    
    echo "=== 版本列表 ==="
    echo ""
    printf "%-20s %-30s %-20s\n" "版本号" "描述" "保存时间"
    echo "--------------------------------------------------------------------------------"
    
    # 倒序显示（最新的在前）
    tac "$info_file" | while IFS='|' read -r version description timestamp; do
        printf "%-20s %-30s %-20s\n" "$version" "$description" "$timestamp"
    done
    
    echo ""
    echo "当前文件: $TARGET_FILE"
    if [ -L "${VERSION_DIR}/${FILE_NAME}.latest" ]; then
        local latest=$(readlink -f "${VERSION_DIR}/${FILE_NAME}.latest" | xargs basename)
        echo "最新版本: $latest"
    fi
}

# 恢复到指定版本
restore_version() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "❌ 请提供版本号"
        echo "用法: $0 restore [版本号]"
        echo ""
        echo "可用版本:"
        list_versions
        exit 1
    fi
    
    # 处理 latest
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
        echo ""
        echo "可用版本:"
        list_versions
        exit 1
    fi
    
    # 备份当前文件
    if [ -f "$TARGET_FILE" ]; then
        local backup_file="${TARGET_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
        cp "$TARGET_FILE" "$backup_file"
        echo "✅ 当前文件已备份到: $backup_file"
    fi
    
    # 恢复版本
    cp "$version_file" "$TARGET_FILE"
    
    # 获取版本信息
    local info_file="${VERSION_DIR}/versions.txt"
    local version_info=$(grep "^${version}|" "$info_file" 2>/dev/null)
    
    echo "✅ 已恢复到版本: $version"
    if [ -n "$version_info" ]; then
        IFS='|' read -r v desc ts <<< "$version_info"
        echo "   描述: $desc"
        echo "   时间: $ts"
    fi
    echo ""
    echo "⚠️  请手动执行以下命令重新构建:"
    echo "   cd /www/wwwroot/feihub/backend"
    echo "   npm run build"
    echo "   pm2 restart feihub-backend"
}

# 显示当前版本信息
show_current() {
    echo "=== 当前版本信息 ==="
    echo ""
    echo "文件: $TARGET_FILE"
    
    if [ ! -f "$TARGET_FILE" ]; then
        echo "❌ 文件不存在"
        exit 1
    fi
    
    local file_size=$(stat -c%s "$TARGET_FILE" 2>/dev/null || stat -f%z "$TARGET_FILE" 2>/dev/null)
    local file_time=$(stat -c%y "$TARGET_FILE" 2>/dev/null || stat -f%Sm "$TARGET_FILE" 2>/dev/null)
    
    echo "大小: $file_size 字节"
    echo "修改时间: $file_time"
    echo ""
    
    # 检查是否匹配某个版本
    local info_file="${VERSION_DIR}/versions.txt"
    if [ -f "$info_file" ]; then
        echo "匹配的版本:"
        for version_file in "${VERSION_DIR}/${FILE_NAME}".v*; do
            if [ -f "$version_file" ]; then
                if cmp -s "$TARGET_FILE" "$version_file" 2>/dev/null; then
                    local version=$(basename "$version_file" | sed "s/${FILE_NAME}\.//")
                    local version_info=$(grep "^${version}|" "$info_file" 2>/dev/null)
                    if [ -n "$version_info" ]; then
                        IFS='|' read -r v desc ts <<< "$version_info"
                        echo "  ✅ $version - $desc ($ts)"
                    else
                        echo "  ✅ $version"
                    fi
                fi
            fi
        done
    fi
}

# 对比版本差异
diff_version() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "❌ 请提供版本号"
        echo "用法: $0 diff [版本号]"
        exit 1
    fi
    
    local version_file="${VERSION_DIR}/${FILE_NAME}.${version}"
    
    if [ ! -f "$version_file" ]; then
        echo "❌ 版本不存在: $version"
        exit 1
    fi
    
    echo "=== 版本对比 ==="
    echo "当前版本 vs $version"
    echo ""
    
    if command -v diff >/dev/null 2>&1; then
        diff -u "$version_file" "$TARGET_FILE" | head -100
    else
        echo "⚠️  diff 命令不可用，无法对比"
    fi
}

# 主逻辑
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

