#!/bin/bash

# Sprunki-Squidki Worker部署脚本
# 这个脚本用于部署Cloudflare Worker，使游戏可以通过自定义域名访问

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

# 设置变量
WRANGLER_PATH="./node_modules/.bin/wrangler"
PROJECT_ROOT=$(dirname "$(cd "$(dirname "$0")" && pwd)")

# 检查wrangler是否存在
if [ ! -f "$WRANGLER_PATH" ]; then
  print_red "[错误] Wrangler未安装，正在尝试安装..."
  cd "$PROJECT_ROOT"
  npm install wrangler
  if [ ! -f "$WRANGLER_PATH" ]; then
    print_red "[错误] Wrangler安装失败，请手动运行 'npm install wrangler'"
    exit 1
  fi
  print_green "[成功] Wrangler已安装"
fi

# 检查环境变量
if [ -f "$PROJECT_ROOT/deploy/.env" ]; then
  source "$PROJECT_ROOT/deploy/.env"
fi

if [ -z "$CLOUDFLARE_API_KEY" ]; then
  print_red "[错误] 未设置CLOUDFLARE_API_KEY环境变量"
  exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
  print_red "[错误] 未设置CLOUDFLARE_ACCOUNT_ID环境变量"
  exit 1
fi

# 设置环境变量
export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_KEY"

# 显示信息
print_blue "[信息] 使用wrangler路径: $WRANGLER_PATH"
print_blue "[信息] 开始部署Worker..."

# 部署Worker
cd "$PROJECT_ROOT"
"$WRANGLER_PATH" deploy

# 检查部署结果
if [ $? -eq 0 ]; then
  print_green "[成功] Worker已成功部署"
  print_blue "[信息] 你的游戏现在可以通过以下URL访问:"
  print_blue "- https://game.sprunkr.online/"
  print_blue "- https://game.sprunkr.online/sprunki-squidki/"
  
  # 提示DNS设置
  print_blue "[信息] 确保在Cloudflare控制台中为域名sprunkr.online设置了正确的DNS记录"
else
  print_red "[错误] Worker部署失败"
  print_blue "[提示] 请检查以下可能的原因:"
  print_blue "1. API令牌权限不足"
  print_blue "2. 账户ID不正确"
  print_blue "3. wrangler.toml配置错误"
  print_blue "4. 网络连接问题"
  print_blue "查看deploy/API令牌指南.md获取更多信息"
fi
