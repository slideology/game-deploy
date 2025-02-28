# Cloudflare API令牌创建指南

要成功部署Worker和使用R2存储桶，你需要创建一个具有足够权限的API令牌。请按照以下步骤操作：

## 创建API令牌

1. 登录到 [Cloudflare控制台](https://dash.cloudflare.com/)
2. 点击右上角的个人头像，然后选择 "我的个人资料"
3. 在左侧菜单中，点击 "API令牌"
4. 点击 "创建令牌" 按钮
5. 选择 "创建自定义令牌"
6. 为令牌命名，例如 "游戏部署令牌"
7. 在权限部分，添加以下权限：
   - Account > Worker Scripts > Edit
   - Account > Workers R2 Storage > Edit
   - Account > Account Settings > Read
   - User > User Details > Read
   - Zone > Zone Settings > Read
   - Zone > Zone > Read
   - Zone > DNS > Edit
8. 在账户资源部分，选择你的账户ID
9. 在区域资源部分，选择 "包括 > 特定区域" 并添加你的域名 sprunkr.online
10. 点击 "继续查看摘要"，然后点击 "创建令牌"
11. 复制生成的令牌

## 更新环境变量

创建令牌后，你需要更新项目中的.env文件：

1. 打开 `/deploy/.env` 文件
2. 将 `CLOUDFLARE_API_KEY` 的值替换为你刚刚创建的新令牌
3. 保存文件

## 测试令牌

要测试令牌是否有效，可以运行以下命令：

```bash
export CLOUDFLARE_API_TOKEN=你的新令牌
wrangler whoami
```

如果成功，你应该能看到你的账户信息和权限列表。

## 注意事项

- API令牌是敏感信息，不要分享给他人
- 不要将令牌提交到版本控制系统
- 如果不再需要，可以在Cloudflare控制台中撤销令牌
