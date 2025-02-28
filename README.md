# Sprunki-Squidki 游戏部署工具

这个项目提供了一套工具，用于将Sprunki-Squidki HTML游戏文件部署到Cloudflare R2对象存储和CDN上，以获得最佳的加载性能和全球分发。现在支持多游戏部署，可以在同一域名下通过不同子路径访问多个游戏。

## 项目结构

```
game-deploy/
├── 404.html                # 自定义404页面，包含游戏链接
├── index.html              # 游戏主文件
├── assets/                 # 游戏资源文件
├── deploy/                 # 部署工具和脚本
│   ├── README.md           # 部署指南
│   ├── upload.sh           # 基本上传脚本
│   ├── upload_games.sh     # 多游戏上传脚本
│   ├── secure_upload.py    # 安全上传脚本
│   ├── chunk_upload.py     # 大文件分块上传脚本
│   ├── wrangler_upload.sh  # 使用wrangler上传脚本
│   ├── analyze.py          # 游戏文件分析工具
│   ├── worker.js           # Cloudflare Worker脚本
│   ├── deploy_worker.sh    # Worker部署脚本
│   ├── 简易部署指南.md      # 简易部署步骤说明
│   ├── API令牌指南.md       # Cloudflare API令牌创建指南
│   └── .env                # 环境变量配置文件
├── wrangler.toml           # Wrangler配置文件
├── package.json            # Node.js依赖配置
├── requirements.txt        # Python依赖配置
├── .gitignore              # Git忽略文件配置
└── 使用指南.md              # 用户使用指南
```

## 功能特点

- **多游戏部署**：支持在同一域名下通过不同子路径部署多个游戏
- **多种上传方式**：支持基本上传、安全上传和大文件分块上传
- **游戏文件分析**：分析游戏文件结构，提取资源和依赖关系
- **多种部署选项**：支持R2公共URL、Cloudflare Pages和Cloudflare Workers
- **自定义域名支持**：可以将游戏部署到自定义域名
- **CDN加速**：利用Cloudflare的全球CDN网络加速游戏加载
- **安全配置**：使用环境变量和.env文件安全存储API密钥
- **自定义404页面**：根路径返回自定义404页面，包含游戏链接

## 快速开始

1. 将游戏HTML文件放在项目根目录，命名为`index.html`
2. 将游戏资源文件放在`assets`目录中
3. 在`deploy/.env`文件中配置Cloudflare API密钥和账户ID
4. 运行上传脚本：
   ```bash
   ./deploy/wrangler_upload.sh
   ```
5. 按照`deploy/简易部署指南.md`中的步骤配置自定义域名

## 多游戏部署

当前支持以下游戏：

1. **Sprunki-Squidki 原版**
   - 访问URL: `https://game.sprunkr.online/sprunki-squidki/`

2. **Sprunki Retake 新版**
   - 访问URL: `https://game.sprunkr.online/sprunki-retake-new-human/`

要部署多个游戏，请使用专门的上传脚本：

```bash
./deploy/upload_games.sh
```

这个脚本会上传两个游戏文件到R2存储桶，并设置正确的路径前缀。根路径 `https://game.sprunkr.online/` 将返回一个404页面，其中包含指向两个游戏的链接。

## 部署选项

我们提供了三种部署方式，详情请参考`deploy/简易部署指南.md`：

1. **R2公共访问URL**：最简单的方法，无需额外配置
2. **Cloudflare Pages**：推荐方法，提供CDN加速和自定义域名支持
3. **Cloudflare Worker**：高级方法，提供最大的灵活性和自定义选项

## 依赖项

- Python 3.6+
- Node.js 14+
- Wrangler CLI（Cloudflare Workers命令行工具）

## 安装依赖

```bash
# 安装Python依赖
pip install -r requirements.txt

# 安装Node.js依赖
npm install
```

## 注意事项

- API密钥是敏感信息，不要将其提交到版本控制系统
- 大文件上传可能需要更长时间，请耐心等待
- 自定义域名需要在Cloudflare控制台中配置DNS记录

## 故障排除

如果遇到问题，请检查：

1. Cloudflare API密钥和账户ID是否正确
2. 网络连接是否稳定
3. 文件大小是否超过限制（单个文件不应超过100MB）
4. API令牌是否具有足够的权限

## 更新日志

- 2025-03-01: 添加多游戏部署支持，可以在同一域名下通过不同子路径访问多个游戏
- 2025-02-28: 初始版本发布，支持基本上传和部署功能
