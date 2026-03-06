#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 三省六部 · Nginx 安装与配置脚本
# 用法: sudo bash nginx/setup.sh [用户名] [密码]
# ═══════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EDICT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色输出
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    error "请使用 sudo 运行此脚本"
    exit 1
fi

# 获取用户名和密码
AUTH_USER="${1:-edict}"
AUTH_PASS="${2:-}"

if [ -z "$AUTH_PASS" ]; then
    echo ""
    read -s -p "请设置访问密码: " AUTH_PASS
    echo ""
    read -s -p "请确认密码: " AUTH_PASS_CONFIRM
    echo ""
    if [ "$AUTH_PASS" != "$AUTH_PASS_CONFIRM" ]; then
        error "两次输入的密码不一致"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     三省六部 · Nginx 配置向导                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# Step 1: 安装 Nginx
# ═══════════════════════════════════════════════════════════════
info "步骤 1/4: 安装 Nginx..."

if command -v nginx &>/dev/null; then
    log "Nginx 已安装: $(nginx -v 2>&1)"
else
    if command -v apt-get &>/dev/null; then
        # Debian/Ubuntu
        apt-get update
        apt-get install -y nginx apache2-utils
    elif command -v yum &>/dev/null; then
        # CentOS/RHEL
        yum install -y nginx httpd-tools
    elif command -v dnf &>/dev/null; then
        # Fedora
        dnf install -y nginx httpd-tools
    else
        error "不支持的系统，请手动安装 Nginx"
        exit 1
    fi
    log "Nginx 安装完成"
fi

# ═══════════════════════════════════════════════════════════════
# Step 2: 创建密码文件
# ═══════════════════════════════════════════════════════════════
info "步骤 2/4: 创建认证密码文件..."

HTPASSWD_FILE="/etc/nginx/.htpasswd_edict"

# 安装 htpasswd 工具（如果没有）
if ! command -v htpasswd &>/dev/null; then
    if command -v apt-get &>/dev/null; then
        apt-get install -y apache2-utils
    else
        yum install -y httpd-tools || dnf install -y httpd-tools
    fi
fi

# 创建密码文件
htpasswd -cb "$HTPASSWD_FILE" "$AUTH_USER" "$AUTH_PASS"
chmod 644 "$HTPASSWD_FILE"

log "密码文件已创建: $HTPASSWD_FILE"
info "用户名: $AUTH_USER"

# ═══════════════════════════════════════════════════════════════
# Step 3: 复制 Nginx 配置
# ═══════════════════════════════════════════════════════════════
info "步骤 3/4: 配置 Nginx..."

NGINX_CONF="$SCRIPT_DIR/edict.conf"

if [ -f "$NGINX_CONF" ]; then
    # 备份原有配置
    if [ -f "/etc/nginx/sites-available/edict" ]; then
        cp "/etc/nginx/sites-available/edict" "/etc/nginx/sites-available/edict.bak.$(date +%Y%m%d-%H%M%S)"
        warn "已备份原有配置"
    fi
    
    # 复制新配置
    cp "$NGINX_CONF" /etc/nginx/sites-available/edict
    
    # 创建符号链接（Debian/Ubuntu 风格）
    if [ -d "/etc/nginx/sites-enabled" ]; then
        rm -f /etc/nginx/sites-enabled/edict
        ln -s /etc/nginx/sites-available/edict /etc/nginx/sites-enabled/edict
        
        # 禁用默认站点（可选）
        if [ -L "/etc/nginx/sites-enabled/default" ]; then
            rm /etc/nginx/sites-enabled/default
            info "已禁用 Nginx 默认站点"
        fi
    else
        # CentOS/RHEL 风格
        cp "$NGINX_CONF" /etc/nginx/conf.d/edict.conf
    fi
    
    log "Nginx 配置已部署"
else
    error "配置文件不存在: $NGINX_CONF"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# Step 4: 测试并重载 Nginx
# ═══════════════════════════════════════════════════════════════
info "步骤 4/4: 测试并重载 Nginx..."

nginx -t && systemctl reload nginx || service nginx reload

if systemctl is-active --quiet nginx || service nginx status &>/dev/null; then
    log "Nginx 配置成功，服务运行中"
else
    systemctl start nginx || service nginx start
    log "Nginx 已启动"
fi

# ═══════════════════════════════════════════════════════════════
# 完成
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     🎉 Nginx 配置完成！                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "访问地址:"
echo "  • 本机: http://127.0.0.1/"
echo "  • 内网: http://$(hostname -I | awk '{print $1}')/"
echo ""
echo "认证信息:"
echo "  用户名: $AUTH_USER"
echo "  密码: ********"
echo ""
echo "管理命令:"
echo "  测试配置: sudo nginx -t"
echo "  重载配置: sudo systemctl reload nginx"
echo "  查看状态: sudo systemctl status nginx"
echo "  查看日志: sudo tail -f /var/log/nginx/access.log"
echo ""
echo "修改密码:"
echo "  sudo htpasswd /etc/nginx/.htpasswd_edict $AUTH_USER"
echo ""
