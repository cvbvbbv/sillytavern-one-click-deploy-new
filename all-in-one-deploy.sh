#!/bin/bash

set -e

echo "==============================================="
echo "        AI应用全功能一体化部署脚本"
echo "    Docker + SillyTavern + Clewdr + Nginx + SSL"
echo "==============================================="

# ===============================================
# 全局变量
# ===============================================
INSTALL_DOCKER=false
INSTALL_SILLYTAVERN=false
INSTALL_CLEWDR=false
SETUP_NGINX=false
SETUP_SSL=false
SSL_PRODUCTION=false

# Nginx相关变量
NGINX_CONFIGS=()
declare -A PORT_DOMAIN_MAP

# SSL相关变量
SSL_EMAIL=""
SSL_DOMAINS=()

# 用户输入数据
CLEWDR_API_PASSWORD=""
CLEWDR_ADMIN_PASSWORD=""
CLEWDR_PROXY=""
CLEWDR_COOKIES=()
CLEWDR_GEMINI_KEYS=()

# ===============================================
# Docker相关函数
# ===============================================
check_docker() {
    echo ">> 检查Docker是否已安装..."
    
    if command -v docker &> /dev/null && docker --version &> /dev/null; then
        echo "✓ 检测到Docker已安装: $(docker --version)"
        
        if docker compose version &> /dev/null; then
            echo "✓ Docker Compose已可用"
            return 0
        else
            echo "⚠ Docker已安装但Docker Compose不可用"
            return 1
        fi
    else
        echo "✗ 未检测到Docker"
        return 1
    fi
}

install_docker() {
    echo "==============================================="
    echo ">> 开始安装Docker..."
    
    echo ">> 更新系统依赖..."
    sudo apt update
    sudo apt upgrade -y
    
    echo ">> 安装Docker（官方源优先，备用镜像源）..."
    
    # 尝试安装Docker
    install_success=false
    
    echo ">> 尝试官方源安装..."
    if sudo curl -fsSL https://get.docker.com | bash; then
        echo ">> 官方源安装脚本执行完成"
        if command -v docker >/dev/null 2>&1; then
            echo "✓ Docker安装成功（官方源）"
            install_success=true
        else
            echo "⚠ 官方源安装脚本执行但Docker命令不可用"
        fi
    else
        echo "⚠ 官方安装脚本执行失败"
    fi
    
    if [ "$install_success" = false ]; then
        echo ">> 尝试阿里云镜像源..."
        if sudo curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun; then
            echo ">> 阿里云镜像安装脚本执行完成"
            if command -v docker >/dev/null 2>&1; then
                echo "✓ Docker安装成功（阿里云镜像）"
                install_success=true
            else
                echo "⚠ 阿里云镜像安装脚本执行但Docker命令不可用"
            fi
        else
            echo "⚠ 阿里云镜像安装脚本执行失败"
        fi
    fi
    
    if [ "$install_success" = false ]; then
        echo "✗ 所有Docker安装方法都失败了"
        exit 1
    fi
    
    # 配置Docker
    echo ">> 配置Docker服务..."
    if ! sudo systemctl is-active docker >/dev/null 2>&1; then
        sudo systemctl start docker 2>/dev/null || true
    fi
    sudo systemctl enable docker 2>/dev/null || true
    
    # 配置用户组
    echo ">> 配置Docker用户组权限..."
    if ! getent group docker > /dev/null 2>&1; then
        sudo groupadd docker
    fi
    sudo usermod -aG docker $USER
    
    echo "✓ Docker安装完成！"
    
    # 强制用户重新登录以获取Docker权限
    echo ""
    echo "==============================================="
    echo "🔄 Docker权限配置完成"
    echo "==============================================="
    echo "⚠ 重要：需要重新登录以获取Docker用户组权限"
    echo ""
    echo "请按照以下步骤操作："
    echo "1. 退出当前SSH连接"
    echo "2. 重新连接到服务器"
    echo "3. 再次运行此脚本: ./all-in-one-deploy.sh"
    echo ""
    echo "脚本将在10秒后自动退出..."
    echo "==============================================="
    
    # 倒计时退出
    for i in {10..1}; do
        echo -n "$i "
        sleep 1
    done
    echo ""
    echo ">> 脚本已退出，请重新连接服务器后继续安装"
    exit 0
}

# ===============================================
# 用户选择菜单
# ===============================================
collect_user_choices() {
    echo "==============================================="
    echo ">> 检查Docker环境"
    echo "==============================================="
    
    # 先检查Docker，如果需要安装就直接安装并退出
    if check_docker; then
        echo "✓ Docker环境就绪，继续配置应用..."
    else
        echo "需要安装Docker"
        while true; do
            read -p "是否安装Docker? (y/n): " docker_choice
            case $docker_choice in
                [Yy]*)
                    install_docker
                    # install_docker函数会exit 0，这里不会执行到
                    ;;
                [Nn]*)
                    echo "Docker是必需的，退出安装"
                    exit 1
                    ;;
                *)
                    echo "请输入 y 或 n"
                    ;;
            esac
        done
    fi
    
    # Docker环境确认后，开始配置应用
    echo ""
    echo "==============================================="
    echo ">> 配置部署选项"
    echo "==============================================="
    
    echo ">> 选择要安装的应用："
    echo "1. 仅安装 SillyTavern酒馆"
    echo "2. 仅安装 Clewdr"
    echo "3. 安装 SillyTavern + Clewdr（推荐）"
    echo "4. 仅配置Nginx和SSL（已有应用）"
    
    while true; do
        read -p "请输入选择 (1-4): " app_choice
        case $app_choice in
            1)
                INSTALL_SILLYTAVERN=true
                echo "✓ 将安装 SillyTavern酒馆"
                break
                ;;
            2)
                INSTALL_CLEWDR=true
                echo "✓ 将安装 Clewdr"
                break
                ;;
            3)
                INSTALL_SILLYTAVERN=true
                INSTALL_CLEWDR=true
                echo "✓ 将安装 SillyTavern + Clewdr"
                break
                ;;
            4)
                echo "✓ 仅配置Nginx和SSL"
                break
                ;;
            *)
                echo "请输入有效选择 (1-4)"
                ;;
        esac
    done
    
    # 询问Nginx配置
    if [ "$INSTALL_SILLYTAVERN" = true ] || [ "$INSTALL_CLEWDR" = true ] || [ "$app_choice" = "4" ]; then
        echo ""
        while true; do
            read -p "是否配置Nginx反向代理? (y/n): " nginx_choice
            case $nginx_choice in
                [Yy]*)
                    SETUP_NGINX=true
                    echo "✓ 将配置Nginx反向代理"
                    
                    # 询问SSL配置
                    while true; do
                        read -p "是否配置SSL证书 (HTTPS)? (y/n): " ssl_choice
                        case $ssl_choice in
                            [Yy]*)
                                SETUP_SSL=true
                                echo "✓ 将配置SSL证书"
                                
                                # 询问SSL环境
                                echo "请选择SSL证书类型："
                                echo "1. 测试环境 (自签名证书，立即可用)"
                                echo "2. 正式环境 (Let's Encrypt证书)"
                                
                                while true; do
                                    read -p "请选择 (1 或 2): " ssl_env_choice
                                    case $ssl_env_choice in
                                        1)
                                            SSL_PRODUCTION=false
                                            echo "✓ 将使用测试环境证书"
                                            break
                                            ;;
                                        2)
                                            SSL_PRODUCTION=true
                                            echo "✓ 将申请正式Let's Encrypt证书"
                                            break
                                            ;;
                                        *)
                                            echo "请输入 1 或 2"
                                            ;;
                                    esac
                                done
                                break
                                ;;
                            [Nn]*)
                                echo ">> 跳过SSL配置"
                                break
                                ;;
                            *)
                                echo "请输入 y 或 n"
                                ;;
                        esac
                    done
                    break
                    ;;
                [Nn]*)
                    echo ">> 跳过Nginx配置"
                    break
                    ;;
                *)
                    echo "请输入 y 或 n"
                    ;;
            esac
        done
    fi
}

# ===============================================
# 收集所有配置信息
# ===============================================
collect_all_configurations() {
    echo "==============================================="
    echo ">> 收集配置信息"
    echo "==============================================="
    
    # 收集Clewdr配置
    if [ "$INSTALL_CLEWDR" = true ]; then
        echo ">> 配置Clewdr参数..."
        read -p "请输入API密钥 (password)，留空为默认: " CLEWDR_API_PASSWORD
        read -p "请输入前端管理密码 (admin_password)，留空为默认: " CLEWDR_ADMIN_PASSWORD
        read -p "请输入代理地址 (proxy)，留空为默认: " CLEWDR_PROXY
        
        echo ">> 配置Claude Pro Cookie（可多个）..."
        while true; do
            read -p "请输入Claude Pro Cookie（留空结束）: " cookie
            [[ -z "$cookie" ]] && break
            CLEWDR_COOKIES+=("$cookie")
        done
        
        echo ">> 配置Gemini API Key（可多个）..."
        while true; do
            read -p "请输入Gemini API Key（留空结束）: " gemini
            [[ -z "$gemini" ]] && break
            CLEWDR_GEMINI_KEYS+=("$gemini")
        done
    fi
    
    # 收集Nginx配置
    if [ "$SETUP_NGINX" = true ]; then
        echo ""
        echo ">> 配置Nginx反向代理..."
        echo "说明：为每个应用配置域名访问"
        
        local config_count=0
        
        # 自动添加应用配置
        if [ "$INSTALL_SILLYTAVERN" = true ]; then
            config_count=$((config_count + 1))
            echo ""
            echo ">>> 配置SillyTavern (端口4160) <<<"
            while true; do
                read -p "请输入SillyTavern的域名 (留空跳过): " st_domain
                if [ -n "$st_domain" ]; then
                    if [[ "$st_domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                        NGINX_CONFIGS+=("4160|$st_domain")
                        PORT_DOMAIN_MAP[4160]="$st_domain"
                        echo "✓ SillyTavern: $st_domain -> 4160"
                        
                        # 如果需要SSL，自动添加到SSL域名列表
                        if [ "$SETUP_SSL" = true ]; then
                            SSL_DOMAINS+=("$st_domain")
                        fi
                        break
                    else
                        echo "⚠ 域名格式无效，请重新输入"
                    fi
                else
                    echo ">> 跳过SillyTavern域名配置"
                    break
                fi
            done
        fi
        
        if [ "$INSTALL_CLEWDR" = true ]; then
            config_count=$((config_count + 1))
            echo ""
            echo ">>> 配置Clewdr (端口8484) <<<"
            while true; do
                read -p "请输入Clewdr的域名 (留空跳过): " clewdr_domain
                if [ -n "$clewdr_domain" ]; then
                    if [[ "$clewdr_domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                        NGINX_CONFIGS+=("8484|$clewdr_domain")
                        PORT_DOMAIN_MAP[8484]="$clewdr_domain"
                        echo "✓ Clewdr: $clewdr_domain -> 8484"
                        
                        # 如果需要SSL，自动添加到SSL域名列表
                        if [ "$SETUP_SSL" = true ]; then
                            SSL_DOMAINS+=("$clewdr_domain")
                        fi
                        break
                    else
                        echo "⚠ 域名格式无效，请重新输入"
                    fi
                else
                    echo ">> 跳过Clewdr域名配置"
                    break
                fi
            done
        fi
        
        # 允许添加额外的代理配置
        if [ "$app_choice" = "4" ] || [ "$config_count" = "0" ]; then
            echo ""
            echo ">> 配置其他代理转发（可选）..."
            while true; do
                config_count=$((config_count + 1))
                echo ""
                echo ">>> 配置第 $config_count 个代理服务 <<<"
                
                read -p "请输入后端服务端口（留空结束）: " backend_port
                if [ -z "$backend_port" ]; then
                    break
                fi
                
                if ! [[ "$backend_port" =~ ^[0-9]+$ ]] || [ "$backend_port" -lt 1 ] || [ "$backend_port" -gt 65535 ]; then
                    echo "⚠ 端口格式无效"
                    config_count=$((config_count - 1))
                    continue
                fi
                
                read -p "请输入域名（留空作为默认服务器）: " domain
                
                if [ -n "$domain" ]; then
                    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                        NGINX_CONFIGS+=("$backend_port|$domain")
                        PORT_DOMAIN_MAP[$backend_port]="$domain"
                        echo "✓ $domain -> $backend_port"
                        
                        # 如果需要SSL，添加到SSL域名列表
                        if [ "$SETUP_SSL" = true ]; then
                            SSL_DOMAINS+=("$domain")
                        fi
                    else
                        echo "⚠ 域名格式无效，跳过此配置"
                        config_count=$((config_count - 1))
                    fi
                else
                    NGINX_CONFIGS+=("$backend_port|")
                    echo "✓ 默认服务器 -> $backend_port"
                fi
            done
        fi
    fi
    
    # 收集SSL配置
    if [ "$SETUP_SSL" = true ]; then
        echo ""
        echo ">> 配置SSL证书..."
        
        # 收集邮箱
        while true; do
            read -p "请输入邮箱地址（用于证书通知）: " SSL_EMAIL
            if [ -z "$SSL_EMAIL" ]; then
                echo "⚠ 邮箱不能为空"
                continue
            fi
            
            if [[ "$SSL_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                echo "✓ 邮箱验证通过: $SSL_EMAIL"
                break
            else
                echo "⚠ 邮箱格式无效"
            fi
        done
        
        # 允许添加额外的SSL域名
        if [ ${#SSL_DOMAINS[@]} -eq 0 ]; then
            echo ">> 配置SSL域名..."
            while true; do
                read -p "请输入域名（留空结束）: " ssl_domain
                if [ -z "$ssl_domain" ]; then
                    if [ ${#SSL_DOMAINS[@]} -eq 0 ]; then
                        echo "⚠ 至少需要一个域名"
                        continue
                    else
                        break
                    fi
                fi
                
                if [[ "$ssl_domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                    SSL_DOMAINS+=("$ssl_domain")
                    echo "✓ 已添加SSL域名: $ssl_domain"
                else
                    echo "⚠ 域名格式无效"
                fi
            done
        fi
    fi
}

# ===============================================
# 显示配置总结
# ===============================================
show_configuration_summary() {
    echo "==============================================="
    echo "📋 配置总结"
    echo "==============================================="
    
    echo "🐳 Docker:"
    if [ "$INSTALL_DOCKER" = true ]; then
        echo "  ✓ 将安装Docker"
    else
        echo "  ✓ 使用现有Docker"
    fi
    
    echo ""
    echo "📱 应用部署:"
    if [ "$INSTALL_SILLYTAVERN" = true ]; then
        echo "  ✓ SillyTavern (端口4160)"
    fi
    if [ "$INSTALL_CLEWDR" = true ]; then
        echo "  ✓ Clewdr (端口8484)"
        echo "    - API密钥: ${CLEWDR_API_PASSWORD:-默认}"
        echo "    - 管理密码: ${CLEWDR_ADMIN_PASSWORD:-默认}"
        echo "    - Cookie数量: ${#CLEWDR_COOKIES[@]}"
        echo "    - Gemini Key数量: ${#CLEWDR_GEMINI_KEYS[@]}"
    fi
    
    echo ""
    echo "🌐 Nginx代理:"
    if [ "$SETUP_NGINX" = true ]; then
        echo "  ✓ 将配置Nginx反向代理"
        for config in "${NGINX_CONFIGS[@]}"; do
            IFS='|' read -r port domain <<< "$config"
            if [ -n "$domain" ]; then
                echo "    - $domain -> 端口$port"
            else
                echo "    - 默认服务器 -> 端口$port"
            fi
        done
    else
        echo "  - 跳过Nginx配置"
    fi
    
    echo ""
    echo "🔒 SSL证书:"
    if [ "$SETUP_SSL" = true ]; then
        if [ "$SSL_PRODUCTION" = true ]; then
            echo "  ✓ Let's Encrypt正式证书"
        else
            echo "  ✓ 自签名测试证书"
        fi
        echo "    - 邮箱: $SSL_EMAIL"
        echo "    - 域名: ${SSL_DOMAINS[*]}"
    else
        echo "  - 跳过SSL配置"
    fi
    
    echo ""
    echo "==============================================="
    
    while true; do
        read -p "确认开始部署? (y/n): " confirm
        case $confirm in
            [Yy]*)
                break
                ;;
            [Nn]*)
                echo "部署已取消"
                exit 0
                ;;
            *)
                echo "请输入 y 或 n"
                ;;
        esac
    done
}

# ===============================================
# Docker应用部署函数
# ===============================================
deploy_sillytavern() {
    echo "==============================================="
    echo ">> 部署SillyTavern酒馆..."
    
    echo ">> 创建项目目录 /opt/sillytavern..."
    sudo mkdir -p /opt/sillytavern
    sudo chown -R $(whoami):$(whoami) /opt/sillytavern
    
    echo ">> 创建docker-compose.yml文件..."
    cat <<EOF | sudo tee /opt/sillytavern/docker-compose.yml > /dev/null
version: '3.8'
services:
  sillytavern:
    container_name: sillytavern
    hostname: sillytavern
    image: ghcr.io/sillytavern/sillytavern:latest
    environment:
      - NODE_ENV=production
      - FORCE_COLOR=1
    ports:
      - "4160:8000"
    volumes:
      - "./config:/home/node/app/config"
      - "./data:/home/node/app/data"
      - "./plugins:/home/node/app/plugins"
      - "./extensions:/home/node/app/public/scripts/extensions/third-party"
    restart: unless-stopped
EOF
    
    echo ">> 启动SillyTavern容器..."
    cd /opt/sillytavern
    if command -v docker >/dev/null 2>&1 && groups $USER | grep -q docker 2>/dev/null && id -nG "$USER" | grep -qw "docker" 2>/dev/null; then
        docker compose up -d --build
    else
        sudo docker compose up -d --build
    fi
    
    echo "✓ SillyTavern部署完成！"
    
    # 显示访问地址
    if [ -n "${PORT_DOMAIN_MAP[4160]}" ]; then
        echo "📝 访问地址: http://${PORT_DOMAIN_MAP[4160]}"
    else
        echo "📝 访问地址: http://你的服务器IP:4160"
    fi
    
    # 等待容器完全启动
    echo ">> 等待SillyTavern服务启动..."
    sleep 10
    
    # 白名单配置是必需的，与Nginx配置无关
    echo ""
    echo "==============================================="
    echo "📋 重要提醒：SillyTavern白名单配置"
    echo "==============================================="
    echo "⚠ SillyTavern默认启用白名单模式"
    echo "⚠ 这是必需的安全配置，无论是否使用域名都需要配置"
    echo "⚠ 不配置将无法正常访问SillyTavern"
    
    if [ -n "${PORT_DOMAIN_MAP[4160]}" ]; then
        echo ""
        echo "💡 您配置了域名访问: ${PORT_DOMAIN_MAP[4160]}"
        echo "   可以选择现在配置或稍后通过域名访问时配置"
    fi
    
    echo ""
    while true; do
        read -p "是否立即配置SillyTavern白名单? (y/n): " config_whitelist
        case $config_whitelist in
            [Yy]*)
                configure_sillytavern_whitelist
                break
                ;;
            [Nn]*)
                echo ""
                echo "==============================================="
                echo "⚠ 已跳过白名单配置"
                echo "==============================================="
                echo "📝 重要提醒："
                echo "   - 您将无法立即访问SillyTavern"
                echo "   - 访问时会看到IP限制错误页面"
                echo "   - 需要手动配置白名单才能使用"
                echo ""
                echo "📋 手动配置方法："
                if [ -n "${PORT_DOMAIN_MAP[8000]}" ]; then
                    echo "   1. 访问 http://${PORT_DOMAIN_MAP[8000]} 或 http://服务器IP:8000"
                else
                    echo "   1. 访问 http://服务器IP:8000"
                fi
                echo "   2. 记录页面显示的公网IP地址"
                echo "   3. 修改 /opt/sillytavern/config/config.yaml"
                echo "   4. 添加IP到白名单并创建账户"
                echo "   5. 创建账户后禁用白名单模式"
                echo ""
                echo "📖 详细配置教程："
                echo "   https://docs.sillytavern.app/installation/docker/"
                echo "==============================================="
                break
                ;;
            *)
                echo "请输入 y 或 n"
                ;;
        esac
    done
}

configure_sillytavern_whitelist() {
    echo "==============================================="
    echo ">> 开始配置SillyTavern白名单..."
    
    CONFIG_PATH="/opt/sillytavern/config/config.yaml"
    
    # 等待配置文件生成
    echo ">> 等待配置文件生成..."
    timeout=30
    while [ $timeout -gt 0 ] && [ ! -f "$CONFIG_PATH" ]; do
        sleep 2
        timeout=$((timeout-2))
        echo "   等待中... ($timeout秒)"
    done
    
    if [ ! -f "$CONFIG_PATH" ]; then
        echo "⚠ 配置文件未生成，请稍后手动配置"
        echo "   访问 http://你的服务器IP:8000 以生成配置文件"
        return 1
    fi
    
    echo "✓ 找到配置文件: $CONFIG_PATH"
    
    # 获取用户IP - 这是第一步！
    echo ""
    echo "📋 重要说明："
    echo "   SillyTavern默认启用白名单模式，需要按顺序完成以下步骤："
    echo "   1. 【现在】添加您的IP到白名单"
    echo "   2. 【然后】访问网站创建账户"
    echo "   3. 【最后】禁用白名单模式"
    echo ""
    
    # 显示访问地址
    if [ -n "${PORT_DOMAIN_MAP[8000]}" ]; then
        echo ">> 请先访问: http://${PORT_DOMAIN_MAP[8000]} 或 http://你的服务器IP:8000"
    else
        echo ">> 请先访问: http://你的服务器IP:8000"
    fi
    echo ">> 您会看到白名单错误页面，请记录页面显示的公网IP地址"
    echo "-----------------------------------------------"
    
    while true; do
        read -p "请输入您的公网IP地址: " USER_IP
        if [ -n "$USER_IP" ]; then
            break
        else
            echo "⚠ IP地址不能为空，请重新输入"
        fi
    done
    
    # 第一步：修改配置文件，添加IP到白名单
    echo ""
    echo "🔧 第一步：添加IP到白名单"
    echo ">> 修改配置文件，移除旧的用户账户和白名单设置..."
    sudo sed -i '/^enableUserAccounts:/d' "$CONFIG_PATH"
    sudo sed -i '/^whitelist:/d' "$CONFIG_PATH"
    sudo sed -i '/^  -/d' "$CONFIG_PATH"
    
    echo ">> 启用用户账户功能..."
    sudo sed -i '/^listen: false/a enableUserAccounts: true' "$CONFIG_PATH"
    
    echo ">> 添加IP地址 $USER_IP 到白名单..."
    sudo sed -i "/^whitelistMode: true/a whitelist:\n  - $USER_IP" "$CONFIG_PATH"
    echo "✓ IP地址已成功添加到白名单"
    
    echo ">> 重启容器以应用白名单配置..."
    cd /opt/sillytavern
    if command -v docker >/dev/null 2>&1 && groups $USER | grep -q docker 2>/dev/null && id -nG "$USER" | grep -qw "docker" 2>/dev/null; then
        docker compose restart sillytavern
    else
        sudo docker compose restart sillytavern
    fi
    
    echo "==============================================="
    
    # 第二步：等待用户创建账户
    echo "🎯 第二步：创建用户账户"
    echo "==============================================="
    echo ">> 配置已更新，请刷新浏览器页面"
    echo ">> 您现在应该能进入SillyTavern并创建账户了"
    echo ""
    if [ -n "${PORT_DOMAIN_MAP[8000]}" ]; then
        echo "📝 访问地址: http://${PORT_DOMAIN_MAP[8000]}"
    else
        echo "📝 访问地址: http://你的服务器IP:8000"
    fi
    echo ""
    echo "⚠ 重要：请完成账户创建和登录 - 这对下一步很关键！"
    echo "-----------------------------------------------"
    
    # 等待用户确认已创建账户
    while true; do
        read -p "已完成账户创建并能正常使用? (y/n): " account_ready
        case $account_ready in
            [Yy]*)
                break
                ;;
            [Nn]*)
                echo "请先完成账户创建，这对下一步很重要！"
                echo "如果遇到问题，可以:"
                echo "  - 检查IP地址是否正确"
                echo "  - 清除浏览器缓存重试"
                echo "  - 查看容器日志: docker logs sillytavern"
                ;;
            *)
                echo "请输入 y 或 n"
                ;;
        esac
    done
    
    # 第三步：禁用白名单模式
    echo ""
    echo "🔧 第三步：禁用白名单模式"
    echo "==============================================="
    echo ">> 修改配置文件以禁用白名单模式..."
    sudo sed -i 's/whitelistMode: true/whitelistMode: false/g' "$CONFIG_PATH"
    echo "✓ whitelistMode已成功更改为false"
    
    echo ">> 重启容器以应用最终配置..."
    cd /opt/sillytavern
    if command -v docker >/dev/null 2>&1 && groups $USER | grep -q docker 2>/dev/null && id -nG "$USER" | grep -qw "docker" 2>/dev/null; then
        docker compose restart sillytavern
    else
        sudo docker compose restart sillytavern
    fi
    
    echo ""
    echo "==============================================="
    echo "🎉 所有配置操作完成！"
    echo "==============================================="
    echo "✅ 白名单模式已禁用"
    echo "✅ 您的SillyTavern现在可供所有人访问"
    
    if [ -n "${PORT_DOMAIN_MAP[8000]}" ]; then
        echo "📝 访问地址: http://${PORT_DOMAIN_MAP[8000]}"
    else
        echo "📝 访问地址: http://你的服务器IP:8000"
    fi
    
    echo ""
    echo "🔒 安全提醒："
    echo "   - 白名单已禁用，任何人都可以访问"
    echo "   - 建议配置Nginx反向代理和SSL证书"
    echo "   - 定期备份重要数据"
    echo "==============================================="
}

# ===============================================
# Clewdr应用部署函数
# ===============================================
deploy_clewdr() {
    echo "==============================================="
    echo ">> 部署Clewdr..."
    
    sudo mkdir -p /etc/clewdr
    cd /etc/clewdr
    
    echo ">> 生成Clewdr配置文件..."
    cat <<EOL | sudo tee clewdr.toml >/dev/null
wasted_cookie = []
ip = "0.0.0.0"
port = 8484
check_update = true
auto_update = false
password = "$CLEWDR_API_PASSWORD"
admin_password = "$CLEWDR_ADMIN_PASSWORD"
proxy = "$CLEWDR_PROXY"
max_retries = 5
preserve_chats = false
web_search = false
cache_response = 0
not_hash_system = false
not_hash_last_n = 0
skip_first_warning = false
skip_second_warning = false
skip_restricted = false
skip_non_pro = false
skip_rate_limit = true
skip_normal_pro = false
use_real_roles = true
custom_prompt = ""
padtxt_len = 4000

[vertex]
EOL
    
    # 添加Cookies
    for cookie in "${CLEWDR_COOKIES[@]}"; do
        echo "[[cookie_array]]" | sudo tee -a clewdr.toml >/dev/null
        echo "cookie = \"$cookie\"" | sudo tee -a clewdr.toml >/dev/null
    done
    
    # 添加Gemini Keys
    for key in "${CLEWDR_GEMINI_KEYS[@]}"; do
        echo "[[gemini_keys]]" | sudo tee -a clewdr.toml >/dev/null
        echo "key = \"$key\"" | sudo tee -a clewdr.toml >/dev/null
    done
    
    # 创建docker-compose文件
    cat <<EOL | sudo tee docker-compose.yml >/dev/null
services:
  clewdr:
    image: ghcr.io/xerxes-2/clewdr:latest
    container_name: clewdr
    hostname: clewdr
    volumes:
      - ./clewdr.toml:/app/clewdr.toml
    network_mode: host
    restart: unless-stopped
EOL
    
    echo ">> 启动Clewdr容器..."
    if command -v docker >/dev/null 2>&1 && groups $USER | grep -q docker 2>/dev/null && id -nG "$USER" | grep -qw "docker" 2>/dev/null; then
        docker compose up -d
    else
        sudo docker compose up -d
    fi
    
    echo "✓ Clewdr部署完成！"
}

# ===============================================
# Nginx配置函数
# ===============================================
setup_nginx() {
    echo "==============================================="
    echo ">> 配置Nginx反向代理..."
    
    # 安装Nginx
    if ! command -v nginx &> /dev/null; then
        echo ">> 安装Nginx..."
        sudo apt update
        sudo apt install nginx -y
    fi
    
    # 确保Nginx运行
    if ! sudo systemctl is-active nginx >/dev/null 2>&1; then
        sudo systemctl start nginx
        sudo systemctl enable nginx
    fi
    
    echo ">> 创建Nginx配置..."
    
    for config in "${NGINX_CONFIGS[@]}"; do
        IFS='|' read -r port domain <<< "$config"
        
        if [ -n "$domain" ]; then
            config_name="${domain//./_}_${port}"
            echo ">> 配置域名 $domain -> 端口 $port"
        else
            config_name="default_server_${port}"
            echo ">> 配置默认服务器 -> 端口 $port"
        fi
        
        config_path="/etc/nginx/sites-available/$config_name"
        
        # 生成HTTP配置
        if [ -n "$domain" ]; then
            sudo tee "$config_path" > /dev/null <<EOF
server {
    listen 80;
    server_name $domain;
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
        else
            sudo tee "$config_path" > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
        fi
        
        # 启用配置
        sudo ln -sf "$config_path" "/etc/nginx/sites-enabled/"
        echo "✓ 配置已创建: $config_name"
    done
    
    # 验证并重载配置
    if sudo nginx -t; then
        sudo systemctl reload nginx
        echo "✓ Nginx配置验证通过并已重载"
    else
        echo "⚠ Nginx配置验证失败"
        exit 1
    fi
}

# ===============================================
# SSL配置函数
# ===============================================
setup_ssl() {
    echo "==============================================="
    echo ">> 配置SSL证书..."
    
    # 安装Certbot
    if ! command -v certbot &> /dev/null; then
        echo ">> 安装Certbot..."
        sudo apt update
        sudo apt install certbot python3-certbot-nginx -y
    fi
    
    if [ "$SSL_PRODUCTION" = true ]; then
        # 正式环境：申请Let's Encrypt证书
        echo ">> 申请Let's Encrypt正式证书..."
        
        for domain in "${SSL_DOMAINS[@]}"; do
            echo ">> 为域名 $domain 申请证书..."
            if sudo certbot --nginx -d "$domain" --email "$SSL_EMAIL" --agree-tos --no-eff-email --non-interactive; then
                echo "✓ 域名 $domain 的证书申请成功"
            else
                echo "⚠ 域名 $domain 的证书申请失败"
            fi
        done
    else
        # 测试环境：生成自签名证书
        echo ">> 生成自签名证书..."
        
        # 先生成证书
        for domain in "${SSL_DOMAINS[@]}"; do
            echo ">> 为域名 $domain 生成自签名证书..."
            
            sudo mkdir -p "/etc/letsencrypt/live/$domain"
            
            sudo openssl genrsa -out "/etc/letsencrypt/live/$domain/privkey.pem" 2048
            sudo openssl req -new -x509 \
                -key "/etc/letsencrypt/live/$domain/privkey.pem" \
                -out "/etc/letsencrypt/live/$domain/fullchain.pem" \
                -days 365 \
                -subj "/CN=$domain" \
                -addext "subjectAltName=DNS:$domain"
            
            echo "✓ 域名 $domain 的自签名证书已生成"
        done
        
        # 然后修改Nginx配置为HTTPS
        echo ">> 更新Nginx配置为HTTPS..."
        
        for domain in "${SSL_DOMAINS[@]}"; do
            # 查找对应的端口
            local domain_port=""
            for config in "${NGINX_CONFIGS[@]}"; do
                IFS='|' read -r port config_domain <<< "$config"
                if [ "$config_domain" = "$domain" ]; then
                    domain_port="$port"
                    break
                fi
            done
            
            if [ -n "$domain_port" ]; then
                config_name="${domain//./_}_${domain_port}_https"
                config_path="/etc/nginx/sites-available/$config_name"
                
                echo ">> 创建HTTPS配置: $domain -> 端口 $domain_port"
                
                sudo tee "$config_path" > /dev/null <<EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1h;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://127.0.0.1:$domain_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
                
                # 删除旧的HTTP配置，启用HTTPS配置
                sudo rm -f "/etc/nginx/sites-enabled/${domain//./_}_${domain_port}"
                sudo ln -sf "$config_path" "/etc/nginx/sites-enabled/"
                
                echo "✓ HTTPS配置已创建: $config_name"
            fi
        done
        
        # 验证并重载配置
        if sudo nginx -t; then
            sudo systemctl reload nginx
            echo "✓ HTTPS配置验证通过并已重载"
            
            # 测试Let's Encrypt配置
            echo ">> 测试Let's Encrypt配置..."
            for domain in "${SSL_DOMAINS[@]}"; do
                echo ">> 测试域名: $domain"
                if sudo certbot certonly --nginx --dry-run -d "$domain" --email "$SSL_EMAIL" --agree-tos --no-eff-email --non-interactive >/dev/null 2>&1; then
                    echo "✓ 域名 $domain 的Let's Encrypt配置测试通过（可升级为正式证书）"
                else
                    echo "⚠ 域名 $domain 的Let's Encrypt配置测试失败（但自签名证书可正常使用）"
                fi
            done
        else
            echo "⚠ HTTPS配置验证失败"
            exit 1
        fi
    fi
}

# ===============================================
# 最终结果显示
# ===============================================
show_final_results() {
    echo "==============================================="
    echo "🎉 部署完成！"
    echo "==============================================="
    
    echo "📱 应用服务："
    if [ "$INSTALL_SILLYTAVERN" = true ]; then
        if [ -n "${PORT_DOMAIN_MAP[8000]}" ]; then
            if [ "$SETUP_SSL" = true ]; then
                echo "  ✅ SillyTavern: https://${PORT_DOMAIN_MAP[8000]}"
            else
                echo "  ✅ SillyTavern: http://${PORT_DOMAIN_MAP[8000]}"
            fi
        else
            echo "  ✅ SillyTavern: http://服务器IP:8000"
        fi
    fi
    
    if [ "$INSTALL_CLEWDR" = true ]; then
        if [ -n "${PORT_DOMAIN_MAP[8484]}" ]; then
            if [ "$SETUP_SSL" = true ]; then
                echo "  ✅ Clewdr: https://${PORT_DOMAIN_MAP[8484]}"
            else
                echo "  ✅ Clewdr: http://${PORT_DOMAIN_MAP[8484]}"
            fi
        else
            echo "  ✅ Clewdr: http://服务器IP:8484"
        fi
    fi
    
    if [ "$SETUP_NGINX" = true ]; then
        echo ""
        echo "🌐 Nginx代理："
        for config in "${NGINX_CONFIGS[@]}"; do
            IFS='|' read -r port domain <<< "$config"
            if [ -n "$domain" ]; then
                if [ "$SETUP_SSL" = true ] && [[ " ${SSL_DOMAINS[@]} " =~ " $domain " ]]; then
                    echo "  ✅ https://$domain -> 端口$port"
                else
                    echo "  ✅ http://$domain -> 端口$port"
                fi
            else
                echo "  ✅ 默认服务器 -> 端口$port"
            fi
        done
    fi
    
    if [ "$SETUP_SSL" = true ]; then
        echo ""
        echo "🔒 SSL证书："
        if [ "$SSL_PRODUCTION" = true ]; then
            echo "  ✅ Let's Encrypt正式证书"
            echo "  📧 续期通知邮箱: $SSL_EMAIL"
        else
            echo "  ✅ 自签名测试证书"
            echo "  ⚠ 浏览器会显示'不安全'，点击'高级' → '继续访问'"
        fi
        
        echo "  📋 SSL域名:"
        for domain in "${SSL_DOMAINS[@]}"; do
            echo "    - $domain"
        done
    fi
    
    echo ""
    echo "🔧 管理命令："
    echo "  查看容器状态: docker ps"
    if [ "$SETUP_NGINX" = true ]; then
        echo "  查看Nginx状态: sudo systemctl status nginx"
        echo "  重载Nginx: sudo systemctl reload nginx"
    fi
    if [ "$SETUP_SSL" = true ] && [ "$SSL_PRODUCTION" = true ]; then
        echo "  查看证书: sudo certbot certificates"
        echo "  测试续期: sudo certbot renew --dry-run"
    fi
    
    echo ""
    echo "💡 重要提醒："
    if [ "$INSTALL_DOCKER" = true ] && ! id -nG "$USER" | grep -qw "docker" 2>/dev/null; then
        echo "  - Docker权限需要重新登录才能生效"
        echo "  - 当前使用sudo运行Docker命令"
    fi
    
    if [ "$INSTALL_SILLYTAVERN" = true ] && [ -z "${PORT_DOMAIN_MAP[8000]}" ] && [ "$SETUP_NGINX" = false ]; then
        echo "  - SillyTavern首次访问可能需要配置白名单"
    fi
    
    echo "==============================================="
}

# ===============================================
# 主程序
# ===============================================
main() {
    # 检查Docker并收集用户选择
    collect_user_choices
    
    # 到这里说明Docker环境已就绪，继续收集配置
    collect_all_configurations
    
    # 显示配置总结
    show_configuration_summary
    
    echo ""
    echo "🚀 开始部署..."
    
    # 部署应用
    if [ "$INSTALL_CLEWDR" = true ]; then
        deploy_clewdr
    fi
    
    if [ "$INSTALL_SILLYTAVERN" = true ]; then
        deploy_sillytavern
    fi
    
    # 等待容器启动
    if [ "$INSTALL_SILLYTAVERN" = true ] || [ "$INSTALL_CLEWDR" = true ]; then
        echo ">> 等待容器完全启动..."
        sleep 10
    fi
    
    # 配置Nginx
    if [ "$SETUP_NGINX" = true ]; then
        setup_nginx
    fi
    
    # 配置SSL
    if [ "$SETUP_SSL" = true ]; then
        setup_ssl
    fi
    
    # 显示最终结果
    show_final_results
}

# 运行主程序
main "$@"
