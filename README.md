# AI应用全功能一体化部署脚本

[![GitHub release](https://img.shields.io/github/release/你的用户名/ai-deploy-script.svg)](https://github.com/你的用户名/ai-deploy-script/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个功能完整的AI应用部署脚本，支持一键安装Docker、SillyTavern酒馆、Clewdr，并自动配置Nginx反向代理和SSL证书。

## ✨ 功能特性

### 🐳 Docker环境管理
- ✅ 自动检测Docker安装状态
- ✅ 支持官方源和阿里云镜像源安装
- ✅ 自动配置Docker服务和用户权限
- ✅ 智能处理用户组权限问题

### 📱 支持的AI应用
- **SillyTavern** 🎭
  - AI角色聊天平台
  - 自动配置白名单和用户账户
  - 完整的两阶段安全配置流程
- **Clewdr** 🤖
  - Claude API代理服务
  - 支持多Cookie和Gemini Key配置
  - 自定义API参数设置

### 🌐 Nginx反向代理
- ✅ 自动安装和配置Nginx
- ✅ 支持多域名代理配置
- ✅ 智能生成配置文件
- ✅ 自动验证和重载配置

### 🔒 SSL证书支持
- **测试环境**: 自签名证书（立即可用，浏览器显示不安全）
- **正式环境**: Let's Encrypt免费证书（受信任的绿色锁）
- ✅ 自动HTTPS重定向配置
- ✅ 支持证书自动续期

## 🚀 快速开始

### 系统要求
- Ubuntu 20.04+ / Debian 10+
- 具有sudo权限的用户
- 网络连接正常

### 一键安装

```bash
# 下载脚本
curl -fsSL https://raw.githubusercontent.com/你的用户名/ai-deploy-script/main/all-in-one-deploy.sh -o all-in-one-deploy.sh

# 给予执行权限
chmod +x all-in-one-deploy.sh

# 运行脚本
./all-in-one-deploy.sh
```

或者使用wget：

```bash
wget https://raw.githubusercontent.com/你的用户名/ai-deploy-script/main/all-in-one-deploy.sh
chmod +x all-in-one-deploy.sh
./all-in-one-deploy.sh
```

## 📖 详细使用教程

### 第一步：选择安装选项

脚本启动后会检查Docker环境，然后引导您选择需要的功能：

```
===============================================
        AI应用全功能一体化部署脚本
    Docker + SillyTavern + Clewdr + Nginx + SSL
===============================================

>> 选择要安装的应用：
1. 仅安装 SillyTavern酒馆
2. 仅安装 Clewdr
3. 安装 SillyTavern + Clewdr（推荐）
4. 仅配置Nginx和SSL（已有应用）
```

### 第二步：配置网络选项

```bash
是否配置Nginx反向代理? (y/n): y
是否配置SSL证书 (HTTPS)? (y/n): y

请选择SSL证书类型：
1. 测试环境 (自签名证书，立即可用)
2. 正式环境 (Let's Encrypt证书)
```

### 第三步：应用详细配置

#### SillyTavern配置
- **域名设置**（可选）: 为SillyTavern配置专用域名
- **⚠️ 白名单配置**（必需）: 这是最重要的步骤！

白名单配置分为三个阶段：
1. **第一阶段**: 添加您的IP到白名单
2. **第二阶段**: 访问网站创建用户账户
3. **第三阶段**: 禁用白名单模式供所有人访问

#### Clewdr配置
- **API密钥**: 用于API访问的密码
- **管理密码**: 用于管理界面的密码
- **Claude Pro Cookies**: 支持添加多个Cookie
- **Gemini API Keys**: 支持添加多个API密钥
- **代理设置**: 可选的网络代理配置

### 第四步：SSL证书配置
- **邮箱地址**: 用于Let's Encrypt证书到期通知
- **域名列表**: 自动从Nginx配置中获取，也可手动添加

## 🔧 高级配置说明

### Docker权限处理

如果检测到需要安装Docker，脚本会在Docker安装完成后自动退出：

```
===============================================
🔄 Docker权限配置完成
===============================================
⚠ 重要：需要重新登录以获取Docker用户组权限

请按照以下步骤操作：
1. 退出当前SSH连接
2. 重新连接到服务器
3. 再次运行此脚本: ./all-in-one-deploy.sh

脚本将在10秒后自动退出...
===============================================
```

这是因为Docker用户组权限需要重新登录才能生效。重新连接后再次运行脚本即可继续安装。

### SillyTavern白名单配置详解

**为什么需要白名单配置？**
- SillyTavern默认启用白名单模式保护安全
- 不配置白名单将无法访问应用
- 必须按正确顺序配置，否则会失败

**正确的配置流程：**

1. **🔧 第一阶段：添加IP到白名单**
   ```
   >> 请先访问: http://你的服务器IP:8000
   >> 您会看到白名单错误页面，请记录页面显示的公网IP地址
   请输入您的公网IP地址: [输入你的IP]
   ```

2. **🎯 第二阶段：创建用户账户**
   ```
   >> 配置已更新，请刷新浏览器页面
   >> 您现在应该能进入SillyTavern并创建账户了
   
   已完成账户创建并能正常使用? (y/n): y
   ```

3. **🔒 第三阶段：禁用白名单模式**
   ```
   >> 修改配置文件以禁用白名单模式...
   ✓ whitelistMode已成功更改为false
   ```
## 🌐 访问地址

### 直接IP访问
```
SillyTavern: http://你的服务器IP:8000
Clewdr: http://你的服务器IP:8484
```

### 域名访问（配置Nginx后）
```bash
# HTTP访问
SillyTavern: http://your-domain.com
Clewdr: http://clewdr.your-domain.com

# HTTPS访问（配置SSL后）
SillyTavern: https://your-domain.com
Clewdr: https://clewdr.your-domain.com
```

## 🔧 日常管理命令

### Docker容器管理
```bash
# 查看所有容器运行状态
docker ps

# 查看应用日志
docker logs sillytavern
docker logs clewdr

# 重启容器
cd /opt/sillytavern && docker compose restart
cd /etc/clewdr && docker compose restart

# 停止容器
docker stop sillytavern clewdr

# 启动容器
docker start sillytavern clewdr

# 更新容器镜像
docker pull ghcr.io/sillytavern/sillytavern:latest
docker pull ghcr.io/xerxes-2/clewdr:latest
```

### Nginx管理
```bash
# 查看Nginx状态
sudo systemctl status nginx

# 启动/停止/重启Nginx
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# 重载配置（不中断服务）
sudo systemctl reload nginx

# 测试配置语法
sudo nginx -t

# 查看访问日志
sudo tail -f /var/log/nginx/access.log

# 查看错误日志
sudo tail -f /var/log/nginx/error.log
```

### SSL证书管理
```bash
# 查看所有证书状态
sudo certbot certificates

# 手动续期所有证书
sudo certbot renew

# 测试续期（不实际执行）
sudo certbot renew --dry-run

# 为新域名申请证书
sudo certbot --nginx -d new-domain.com

# 查看证书详细信息
sudo openssl x509 -in /etc/letsencrypt/live/你的域名/fullchain.pem -text -noout
```

## 🛠️ 常见问题排除

### Docker相关问题

**Q: 提示Docker权限错误？**
```bash
# 解决方法：添加当前用户到docker组
sudo usermod -aG docker $USER

# 然后重新登录，或使用以下命令临时生效
newgrp docker
```

**Q: Docker服务启动失败？**
```bash
# 检查Docker服务状态
sudo systemctl status docker

# 查看详细错误日志
sudo journalctl -u docker.service

# 重启Docker服务
sudo systemctl restart docker
```

### SillyTavern访问问题

**Q: 访问时显示白名单错误？**

这是正常现象，说明需要配置白名单：

1. 记录错误页面显示的IP地址
2. 编辑配置文件：
```bash
sudo nano /opt/sillytavern/config/config.yaml
```
3. 添加你的IP到whitelist部分：
```yaml
whitelist:
  - 你的公网IP
```
4. 重启容器：
```bash
cd /opt/sillytavern && docker compose restart
```

**Q: SillyTavern无法启动？**
```bash
# 查看容器日志
docker logs sillytavern

# 检查端口占用
sudo netstat -tlnp | grep 8000

# 重新构建容器
cd /opt/sillytavern
docker compose down
docker compose up -d --build
```

### Nginx配置问题

**Q: Nginx配置测试失败？**
```bash
# 检查配置语法
sudo nginx -t

# 如果有错误，查看具体错误信息
sudo nginx -T

# 查看错误日志
sudo tail -20 /var/log/nginx/error.log
```

**Q: 域名无法访问？**

检查以下几点：
1. 域名DNS解析是否正确指向服务器IP
2. 防火墙是否开放80和443端口
3. Nginx配置是否正确

```bash
# 检查DNS解析
nslookup 你的域名

# 检查防火墙状态
sudo ufw status

# 开放必要端口
sudo ufw allow 80
sudo ufw allow 443
```

### SSL证书问题

**Q: Let's Encrypt证书申请失败？**

常见原因和解决方法：
1. **域名解析问题**：确保域名正确解析到服务器IP
2. **端口被阻挡**：确保80端口可以从外网访问
3. **申请频率限制**：Let's Encrypt有申请频率限制

```bash
# 查看详细错误日志
sudo tail -50 /var/log/letsencrypt/letsencrypt.log

# 使用测试环境验证配置
sudo certbot --nginx --dry-run -d 你的域名

# 手动申请证书（如果自动申请失败）
sudo certbot certonly --nginx -d 你的域名
```

**Q: 自签名证书浏览器提示不安全？**

这是正常现象，自签名证书会显示"连接不安全"：
1. 点击浏览器的"高级"选项
2. 选择"继续访问"或"接受风险并继续"
3. 如需受信任的证书，请使用Let's Encrypt正式环境

## 📝 配置文件详解

### SillyTavern配置文件 (config.yaml)

关键配置项说明：
```yaml
# 服务器监听设置
listen: false              # 是否只监听本地
whitelistMode: false       # 白名单模式（生产环境建议设为false）
enableUserAccounts: true   # 启用用户账户功能

# 白名单IP列表
whitelist:
  - 192.168.1.100          # 允许访问的IP地址
  - 10.0.0.5

# 其他重要设置
port: 8000                 # 服务端口
autorun: true             # 自动运行
```

### Clewdr配置文件 (clewdr.toml)

```toml
# 基本网络设置
ip = "0.0.0.0"           # 监听所有IP
port = 8484              # 服务端口

# 认证设置
password = "your-api-key"           # API访问密钥
admin_password = "your-admin-pwd"   # 管理界面密码

# 代理设置
proxy = "http://proxy:8080"  # 可选的代理服务器

# Claude Cookie配置
[[cookie_array]]
cookie = "your-claude-cookie-here"

# Gemini API配置
[[gemini_keys]]
key = "your-gemini-api-key-here"

# 高级设置
max_retries = 5           # 最大重试次数
skip_rate_limit = true    # 跳过速率限制
cache_response = 0        # 响应缓存时间（秒）
```

## ⚠️ 安全建议

### 1. 系统安全
```bash
# 定期更新系统
sudo apt update && sudo apt upgrade -y

# 配置防火墙
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# 禁用root登录（可选）
sudo nano /etc/ssh/sshd_config
# 设置 PermitRootLogin no
sudo systemctl restart sshd
```

### 2. 应用安全
```bash
# 定期更新Docker镜像
docker pull ghcr.io/sillytavern/sillytavern:latest
docker pull ghcr.io/xerxes-2/clewdr:latest

# 使用强密码
# - Clewdr的API密钥和管理密码
# - 服务器SSH密码或密钥认证

# 定期备份重要数据
tar -czf sillytavern-backup-$(date +%Y%m%d).tar.gz /opt/sillytavern/config /opt/sillytavern/data
cp /etc/clewdr/clewdr.toml ~/clewdr-backup-$(date +%Y%m%d).toml
```

### 3. 网络安全
- 使用HTTPS（Let's Encrypt证书）
- 定期检查访问日志
- 考虑使用CloudFlare等CDN服务
- 不要在公网暴露管理端口

## 📊 性能优化

### Docker容器优化
```bash
# 限制容器资源使用
# 在docker-compose.yml中添加：
services:
  sillytavern:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

### Nginx优化
```nginx
# 在nginx配置中添加性能优化
gzip on;
gzip_types text/plain text/css application/json application/javascript;

# 启用HTTP/2
listen 443 ssl http2;

# 配置缓存
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## 🔄 备份与恢复

### 创建备份脚本
```bash
#!/bin/bash
# backup.sh - 自动备份脚本

BACKUP_DIR="/home/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份SillyTavern
echo "备份SillyTavern..."
tar -czf $BACKUP_DIR/sillytavern_$DATE.tar.gz /opt/sillytavern/config /opt/sillytavern/data

# 备份Clewdr
echo "备份Clewdr..."
cp /etc/clewdr/clewdr.toml $BACKUP_DIR/clewdr_$DATE.toml

# 备份Nginx配置
echo "备份Nginx配置..."
tar -czf $BACKUP_DIR/nginx_$DATE.tar.gz /etc/nginx/sites-available /etc/nginx/sites-enabled

# 备份SSL证书
echo "备份SSL证书..."
tar -czf $BACKUP_DIR/ssl_$DATE.tar.gz /etc/letsencrypt

# 清理30天前的备份
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
find $BACKUP_DIR -name "*.toml" -mtime +30 -delete

echo "备份完成：$BACKUP_DIR"
```

### 恢复数据
```bash
# 恢复SillyTavern数据
sudo tar -xzf sillytavern_backup.tar.gz -C /

# 恢复Clewdr配置
sudo cp clewdr_backup.toml /etc/clewdr/clewdr.toml

# 重启服务
docker compose restart
```

## 🆘 获取帮助

### 官方文档
- **SillyTavern官方文档**: https://docs.sillytavern.app/
- **Clewdr项目地址**: https://github.com/xerxes-2/clewdr
- **Nginx官方文档**: https://nginx.org/en/docs/
- **Let's Encrypt文档**: https://letsencrypt.org/docs/

### 社区支持
- **GitHub Issues**: [提交问题和建议](https://github.com/你的用户名/ai-deploy-script/issues)
- **讨论区**: [参与讨论](https://github.com/你的用户名/ai-deploy-script/discussions)

### 常用检查命令
```bash
# 一键状态检查脚本
echo "=== Docker状态 ==="
docker ps
echo "=== Nginx状态 ==="
sudo systemctl status nginx --no-pager
echo "=== SSL证书状态 ==="
sudo certbot certificates
echo "=== 端口占用 ==="
sudo netstat -tlnp | grep -E ':80|:443|:8000|:8484'
```

## 📄 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。

## 🤝 贡献指南

欢迎提交Pull Request和Issue！

### 贡献步骤
1. Fork 这个仓库
2. 创建特性分支: `git checkout -b feature/amazing-feature`
3. 提交更改: `git commit -m 'Add amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 提交Pull Request

### 开发建议
- 保持代码简洁易读
- 添加适当的注释
- 测试新功能的兼容性
- 更新相关文档

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=你的用户名/ai-deploy-script&type=Date)](https://star-history.com/#你的用户名/ai-deploy-script&Date)

## 📈 更新日志

### v1.0.0 (2025-08-14)
- ✨ 初始版本发布
- ✅ 支持Docker自动安装
- ✅ 支持SillyTavern和Clewdr部署
- ✅ 支持Nginx反向代理配置
- ✅ 支持SSL证书自动申请
- ✅ 完整的白名单配置流程

---

**❤️ 如果这个脚本对您有帮助，请给个Star支持一下！**

**🚀 让AI应用部署变得更简单！**
