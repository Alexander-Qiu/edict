# Nginx 反向代理配置

为三省六部 Edict 看板提供外网访问和密码保护。

## 快速安装

### 方式一：使用预置账号（推荐）

已配置好用户名 `Alexander`，密码 `qrz000328`：

```bash
cd /path/to/edict
sudo bash nginx/setup.sh Alexander qrz000328
```

### 方式二：自定义账号

```bash
# 进入项目目录
cd /path/to/edict

# 运行安装脚本（需要 sudo），交互式设置密码
sudo bash nginx/setup.sh

# 或指定用户名和密码
sudo bash nginx/setup.sh myusername mypassword
```

## 手动安装

### 1. 安装 Nginx

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y nginx apache2-utils

# CentOS/RHEL
sudo yum install -y nginx httpd-tools
```

### 2. 创建密码文件

```bash
# 创建密码文件（edict 是用户名）
sudo htpasswd -c /etc/nginx/.htpasswd_edict edict

# 添加更多用户
sudo htpasswd /etc/nginx/.htpasswd_edict anotheruser
```

### 3. 复制配置文件

```bash
# Ubuntu/Debian
sudo cp nginx/edict.conf /etc/nginx/sites-available/edict
sudo ln -s /etc/nginx/sites-available/edict /etc/nginx/sites-enabled/edict
sudo rm -f /etc/nginx/sites-enabled/default

# CentOS/RHEL
sudo cp nginx/edict.conf /etc/nginx/conf.d/edict.conf
```

### 4. 启动 Nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
# 或
sudo service nginx reload
```

## 访问

- **本地**: http://127.0.0.1/
- **内网**: http://你的内网IP/
- **公网**: http://你的公网IP/ （需在防火墙开放 80 端口）

输入用户名密码后即可访问看板。

## HTTPS 配置（推荐）

如果你有域名和 SSL 证书，编辑 `/etc/nginx/sites-available/edict`，取消 HTTPS server 块的注释：

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;
    
    # ... 其他配置
}
```

使用 Let's Encrypt 免费证书：

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## 防火墙配置

```bash
# Ubuntu (UFW)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# CentOS (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## 安全建议

1. **不要使用默认密码** - 安装时设置强密码
2. **启用 HTTPS** - 防止密码明文传输
3. **限制 IP 访问** - 可以修改配置只允许特定 IP
4. **修改默认端口** - 如果需要，修改监听端口

## 故障排查

```bash
# 检查 Nginx 配置
sudo nginx -t

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# 查看访问日志
sudo tail -f /var/log/nginx/access.log

# 检查 Edict 服务是否运行
curl http://127.0.0.1:8989/api/live-status

# 检查端口占用
sudo netstat -tlnp | grep 80
```
