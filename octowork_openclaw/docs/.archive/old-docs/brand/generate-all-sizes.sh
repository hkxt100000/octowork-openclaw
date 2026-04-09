#!/bin/bash

# OctoWork Logo 批量生成脚本
# 基于源文件生成所有需要的尺寸

set -e

SOURCE_DIR="source"
SOURCE_FILE="$SOURCE_DIR/octowork-logo-master-1024.png"

echo "🎨 开始生成 OctoWork Logo 所有尺寸..."
echo "📁 源文件: $SOURCE_FILE"
echo ""

# 检查源文件
if [ ! -f "$SOURCE_FILE" ]; then
    echo "❌ 错误: 源文件不存在"
    exit 1
fi

# ============================================
# 第一批：网站Logo（9个）
# ============================================
echo "🌐 第一批：生成网站Logo（9个）..."

# Header Logo - 保持宽高比
convert "$SOURCE_FILE" -resize 200x60 -background none -gravity center -extent 200x60 website/header-logo.png
convert "$SOURCE_FILE" -resize 400x120 -background none -gravity center -extent 400x120 website/header-logo@2x.png

# Header Logo - 深色背景版（反色）
convert "$SOURCE_FILE" -resize 200x60 -background none -gravity center -extent 200x60 -negate website/header-logo-dark.png
convert "$SOURCE_FILE" -resize 400x120 -background none -gravity center -extent 400x120 -negate website/header-logo-dark@2x.png

# Footer Logo
convert "$SOURCE_FILE" -resize 150x45 -background none -gravity center -extent 150x45 website/footer-logo.png
convert "$SOURCE_FILE" -resize 300x90 -background none -gravity center -extent 300x90 website/footer-logo@2x.png

# Hero Logo
convert "$SOURCE_FILE" -resize 400x120 -background none -gravity center -extent 400x120 website/hero-logo.png

# Hero Icon（裁剪只保留章鱼图标部分，无文字）
convert "$SOURCE_FILE" -resize 256x256 -background none -gravity north -extent 256x256 website/hero-icon.png
convert "$SOURCE_FILE" -resize 512x512 -background none -gravity north -extent 512x512 website/hero-icon@2x.png

echo "✅ 网站Logo生成完成（9个）"
echo ""

# ============================================
# 第二批：Favicon基础（6个）
# ============================================
echo "🔖 第二批：生成Favicon基础（6个）..."

convert "$SOURCE_FILE" -resize 16x16 -background none -gravity north -extent 16x16 favicon/favicon-16.png
convert "$SOURCE_FILE" -resize 32x32 -background none -gravity north -extent 32x32 favicon/favicon-32.png
convert "$SOURCE_FILE" -resize 48x48 -background none -gravity north -extent 48x48 favicon/favicon-48.png
convert "$SOURCE_FILE" -resize 180x180 -background none -gravity north -extent 180x180 favicon/apple-touch-icon.png
convert "$SOURCE_FILE" -resize 192x192 -background none -gravity north -extent 192x192 favicon/android-chrome-192.png
convert "$SOURCE_FILE" -resize 512x512 -background none -gravity north -extent 512x512 favicon/android-chrome-512.png

# 生成.ico文件（包含多个尺寸）
convert favicon/favicon-16.png favicon/favicon-32.png favicon/favicon-48.png favicon/favicon.ico

echo "✅ Favicon基础生成完成（6个+1个ICO）"
echo ""

# ============================================
# 第三批：社交媒体头像（7个）
# ============================================
echo "🌍 第三批：生成社交媒体头像（7个）..."

convert "$SOURCE_FILE" -resize 400x400 -background none -gravity center -extent 400x400 social-media/profile-twitter.png
convert "$SOURCE_FILE" -resize 400x400 -background none -gravity center -extent 400x400 social-media/profile-linkedin.png
convert "$SOURCE_FILE" -resize 500x500 -background none -gravity center -extent 500x500 social-media/profile-github.png
convert "$SOURCE_FILE" -resize 500x500 -background none -gravity center -extent 500x500 social-media/profile-wechat.png
convert "$SOURCE_FILE" -resize 800x800 -background none -gravity center -extent 800x800 social-media/profile-weibo.png

# OG分享图（带白色背景）
convert "$SOURCE_FILE" -resize 1200x630 -background white -gravity center -extent 1200x630 social-media/og-image.png
convert "$SOURCE_FILE" -resize 1200x1200 -background white -gravity center -extent 1200x1200 social-media/og-image-square.png

echo "✅ 社交媒体头像生成完成（7个）"
echo ""

# ============================================
# 统计
# ============================================
echo ""
echo "🎉 第一批核心Logo生成完成！"
echo ""
echo "📊 统计："
echo "  🌐 网站Logo: $(ls website/*.png 2>/dev/null | wc -l) 个"
echo "  🔖 Favicon: $(ls favicon/*.png 2>/dev/null | wc -l) 个PNG + 1 个ICO"
echo "  🌍 社交媒体: $(ls social-media/*.png 2>/dev/null | wc -l) 个"
echo ""
echo "  ✅ 总计: 22个核心文件已生成"
echo ""
echo "📁 文件位置："
echo "  - website/"
echo "  - favicon/"
echo "  - social-media/"
echo ""
echo "✨ 完成！所有文件已准备就绪。"
