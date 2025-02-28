#!/bin/bash

# Sprunki-Squidki 配置更新脚本
# 这个脚本帮助你更新游戏的部署配置

# 设置颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 打印带颜色的消息
print_green() {
  echo -e "${GREEN}$1${NC}"
}

print_blue() {
  echo -e "${BLUE}$1${NC}"
}

print_red() {
  echo -e "${RED}$1${NC}"
}

# 显示欢迎信息
print_green "======================================"
print_green "  Sprunki-Squidki 配置更新工具"
print_green "======================================"
echo ""

# 检查是否有launch.html文件
if [ -f "../launch.html" ]; then
  print_blue "✓ 启动页面已准备就绪"
else
  print_red "✗ 未找到启动页面，请确保launch.html文件存在"
fi

# 检查R2存储桶名称
print_blue "当前R2存储桶名称: game-assets"
read -p "是否要更改R2存储桶名称？(y/n): " change_bucket
if [ "$change_bucket" = "y" ]; then
  read -p "请输入新的R2存储桶名称: " new_bucket
  # 更新.env文件
  sed -i '' "s/CLOUDFLARE_BUCKET_NAME=.*/CLOUDFLARE_BUCKET_NAME=$new_bucket/" ../.env
  # 更新wrangler.toml文件
  sed -i '' "s/bucket_name = \"game-assets\"/bucket_name = \"$new_bucket\"/" ../wrangler.toml
  print_green "✓ R2存储桶名称已更新为: $new_bucket"
fi

# 检查自定义域名
print_blue "当前自定义域名: game.sprunkr.online"
read -p "是否要更改自定义域名？(y/n): " change_domain
if [ "$change_domain" = "y" ]; then
  read -p "请输入新的自定义域名: " new_domain
  # 更新wrangler.toml文件
  sed -i '' "s/pattern = \"game.sprunkr.online/pattern = \"$new_domain/" ../wrangler.toml
  print_green "✓ 自定义域名已更新为: $new_domain"
fi

# 确认更新
echo ""
print_green "配置更新完成！"
echo ""
print_blue "下一步操作:"
echo "1. 运行 ./deploy/wrangler_upload.sh 上传文件到R2存储桶"
echo "2. 按照 ./deploy/简易部署指南.md 中的步骤配置Cloudflare Pages"
echo ""

# 询问是否立即上传文件
read -p "是否立即上传文件到R2存储桶？(y/n): " upload_now
if [ "$upload_now" = "y" ]; then
  print_blue "开始上传文件..."
  cd ..
  ./deploy/wrangler_upload.sh
fi
