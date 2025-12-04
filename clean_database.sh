#!/bin/bash

# iContentProduction 数据库清理脚本
# 用于清理 SwiftData 数据库，解决 schema 变更导致的启动错误

echo "========================================="
echo "iContentProduction 数据库清理工具"
echo "========================================="
echo ""

# 查找应用容器目录
CONTAINER_PATH=$(find ~/Library/Containers -maxdepth 1 -name "*iContentProduction*" 2>/dev/null | head -n 1)

if [ -z "$CONTAINER_PATH" ]; then
    echo "❌ 未找到 iContentProduction 应用容器"
    echo ""
    echo "可能的原因："
    echo "1. 应用从未运行过"
    echo "2. 应用的 Bundle Identifier 不包含 'iContentProduction'"
    echo ""
    echo "手动查找方法："
    echo "打开 Finder，按 Cmd+Shift+G，输入: ~/Library/Containers"
    echo "然后查找与你的应用相关的文件夹"
    exit 1
fi

echo "✅ 找到应用容器: $CONTAINER_PATH"
echo ""

# 查找数据库文件
echo "正在查找数据库文件..."
DB_FILES=$(find "$CONTAINER_PATH" -name "*.store" -o -name "*.sqlite" -o -name "*.db" 2>/dev/null)

if [ -z "$DB_FILES" ]; then
    echo "⚠️  未找到数据库文件"
    echo ""
    echo "这可能意味着："
    echo "1. 应用从未成功创建数据库"
    echo "2. 数据库文件使用了不同的扩展名"
    echo ""
    echo "是否要删除整个应用容器？这将清除所有应用数据。"
    read -p "输入 'yes' 继续，或按回车取消: " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo ""
        echo "正在删除应用容器..."
        rm -rf "$CONTAINER_PATH"
        echo "✅ 应用容器已删除: $CONTAINER_PATH"
        echo ""
        echo "请重新运行应用，它将创建全新的数据库。"
    else
        echo "操作已取消"
    fi
    exit 0
fi

echo "找到以下数据库文件："
echo "$DB_FILES"
echo ""

# 询问用户确认
echo "⚠️  警告：此操作将删除所有应用数据，包括："
echo "  - 所有已创建的内容"
echo "  - 所有设置和配置"
echo "  - 所有历史记录"
echo ""
read -p "确认删除？输入 'yes' 继续，或按回车取消: " confirm

if [ "$confirm" != "yes" ]; then
    echo "操作已取消"
    exit 0
fi

# 备份选项
echo ""
read -p "是否要先备份数据？(y/n): " backup

if [ "$backup" = "y" ] || [ "$backup" = "Y" ]; then
    BACKUP_DIR="$HOME/Desktop/iContentProduction_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONTAINER_PATH" "$BACKUP_DIR/"
    echo "✅ 已备份到: $BACKUP_DIR"
    echo ""
fi

# 删除数据库文件
echo "正在删除数据库文件..."
while IFS= read -r file; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✓ 已删除: $(basename "$file")"
    fi
done <<< "$DB_FILES"

# 同时删除相关的辅助文件
find "$CONTAINER_PATH" -name "*.store-shm" -delete 2>/dev/null
find "$CONTAINER_PATH" -name "*.store-wal" -delete 2>/dev/null
find "$CONTAINER_PATH" -name "*.sqlite-shm" -delete 2>/dev/null
find "$CONTAINER_PATH" -name "*.sqlite-wal" -delete 2>/dev/null

echo ""
echo "========================================="
echo "✅ 数据库清理完成！"
echo "========================================="
echo ""
echo "下一步："
echo "1. 在 Xcode 中重新运行应用"
echo "2. 应用将自动创建新的数据库"
echo "3. 新的 schema 将包含所有新增字段"
echo ""
