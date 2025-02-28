#!/bin/bash

# Sprunki-Squidki 游戏文件上传脚本（带子路径前缀）
# 这个脚本将游戏文件上传到R2存储桶，并添加sprunki-squidki前缀

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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WRANGLER_PATH="$PROJECT_ROOT/node_modules/.bin/wrangler"
BUCKET_NAME="game-assets"
PREFIX="sprunki-squidki/"

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
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
fi

if [ -z "$CLOUDFLARE_API_KEY" ]; then
  print_red "[错误] 未设置CLOUDFLARE_API_KEY环境变量"
  exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
  print_red "[错误] 未设置CLOUDFLARE_ACCOUNT_ID环境变量"
  exit 1
fi

if [ -n "$CLOUDFLARE_BUCKET_NAME" ]; then
  BUCKET_NAME="$CLOUDFLARE_BUCKET_NAME"
fi

# 设置环境变量
export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_KEY"

# 显示信息
print_blue "[信息] 使用wrangler路径: $WRANGLER_PATH"
print_blue "[信息] 使用R2存储桶: $BUCKET_NAME"
print_blue "[信息] 使用子路径前缀: $PREFIX"
print_blue "[信息] 开始上传游戏文件..."

# 上传index.html
print_blue "[信息] 上传index.html..."
"$WRANGLER_PATH" r2 object put "$BUCKET_NAME:${PREFIX}index.html" --file "$PROJECT_ROOT/index.html" --content-type "text/html"

# 上传redirect.html到根目录
print_blue "[信息] 上传redirect.html到根目录..."
"$WRANGLER_PATH" r2 object put "$BUCKET_NAME:index.html" --file "$PROJECT_ROOT/redirect.html" --content-type "text/html"

# 上传其他文件
print_blue "[信息] 上传其他文件..."
find "$PROJECT_ROOT" -type f -not -path "*/node_modules/*" -not -path "*/\.*" -not -path "*/deploy/*" -not -name "index.html" -not -name "redirect.html" -not -name "*.md" -not -name "*.toml" -not -name "*.json" -not -name "*.sh" | while read -r file; do
  # 计算相对路径
  rel_path="${file#$PROJECT_ROOT/}"
  # 添加前缀
  target_path="${PREFIX}${rel_path}"
  
  # 获取文件扩展名
  ext="${file##*.}"
  content_type=""
  
  # 设置内容类型
  case "$ext" in
    html) content_type="text/html" ;;
    css) content_type="text/css" ;;
    js) content_type="application/javascript" ;;
    json) content_type="application/json" ;;
    png) content_type="image/png" ;;
    jpg|jpeg) content_type="image/jpeg" ;;
    gif) content_type="image/gif" ;;
    svg) content_type="image/svg+xml" ;;
    ico) content_type="image/x-icon" ;;
    txt) content_type="text/plain" ;;
    mp3) content_type="audio/mpeg" ;;
    mp4) content_type="video/mp4" ;;
    webp) content_type="image/webp" ;;
    woff) content_type="font/woff" ;;
    woff2) content_type="font/woff2" ;;
    ttf) content_type="font/ttf" ;;
    otf) content_type="font/otf" ;;
    *) content_type="application/octet-stream" ;;
  esac
  
  # 上传文件
  if [ -n "$content_type" ]; then
    print_blue "[信息] 上传 $rel_path 到 $target_path (类型: $content_type)..."
    "$WRANGLER_PATH" r2 object put "$BUCKET_NAME:$target_path" --file "$file" --content-type "$content_type"
  else
    print_blue "[信息] 上传 $rel_path 到 $target_path..."
    "$WRANGLER_PATH" r2 object put "$BUCKET_NAME:$target_path" --file "$file"
  fi
done

# 检查上传结果
if [ $? -eq 0 ]; then
  print_green "[成功] 游戏文件已成功上传到R2存储桶"
  print_blue "[信息] 你的游戏现在可以通过以下URL访问:"
  print_blue "- 通过Worker: https://game.sprunkr.online/sprunki-squidki/"
  print_blue "- 直接访问R2: https://pub-$BUCKET_NAME.r2.dev/sprunki-squidki/index.html (如果启用了公共访问)"
else
  print_red "[错误] 游戏文件上传失败"
  print_blue "[提示] 请检查以下可能的原因:"
  print_blue "1. API令牌权限不足"
  print_blue "2. 账户ID不正确"
  print_blue "3. R2存储桶不存在"
  print_blue "4. 网络连接问题"
  print_blue "查看deploy/API令牌指南.md获取更多信息"
fi
