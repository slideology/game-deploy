#!/bin/bash

# 简单Worker部署脚本
# 这个脚本部署一个简单的Worker，直接从R2存储桶提供内容

# 设置变量
WRANGLER_PATH="./node_modules/.bin/wrangler"
WORKER_NAME="game-site"
WORKER_JS="./deploy/simple-r2-worker.js"
DOMAIN="game.sprunkr.online"

# 检查wrangler是否存在
if [ ! -f "$WRANGLER_PATH" ]; then
  echo "[错误] Wrangler未安装，请先运行 'npm install'"
  exit 1
fi

# 创建临时wrangler.toml文件
cat > wrangler.temp.toml << EOF
name = "$WORKER_NAME"
main = "$WORKER_JS"
compatibility_date = "2023-09-01"

# 绑定R2存储桶
[[r2_buckets]]
binding = "BUCKET"
bucket_name = "game-assets"

# 自定义域名配置
routes = [
  { pattern = "$DOMAIN/*", zone_name = "sprunkr.online" }
]
EOF

echo "[信息] 临时配置文件已创建"

# 部署Worker
echo "[信息] 开始部署Worker..."
$WRANGLER_PATH deploy --config wrangler.temp.toml

# 检查部署结果
if [ $? -eq 0 ]; then
  echo "[成功] Worker已成功部署"
  echo "[信息] 你的游戏现在可以通过 https://$DOMAIN 访问"
else
  echo "[错误] Worker部署失败"
fi

# 清理临时文件
rm wrangler.temp.toml
echo "[信息] 临时配置文件已删除"
