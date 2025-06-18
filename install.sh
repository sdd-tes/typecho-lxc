#!/bin/bash

set -e

echo "📦 正在更新软件源..."
#应为lxc环境太杂了
apt clean
rm -rf /var/lib/apt/lists/*
apt update --fix-missing
apt update
echo "📥 安装 Nginx、PHP 组件（仅需核心）..."
apt install -y nginx php php-fpm php-sqlite3 unzip wget curl
apt install -y php-mbstring
echo "📁 创建网站目录..."
mkdir -p /var/www/typecho
cd /var/www/typecho

echo "⬇️ 安装 Typecho 最新版和一部分美化中..."
wget -O typecho.zip https://github.com/typecho/typecho/releases/latest/download/typecho.zip
unzip typecho.zip
chown -R www-data:www-data /var/www/typecho
chown -R www-data:www-data /var/www/typecho
chmod -R 755 /var/www/typecho

mkdir -p /var/www/typecho/usr/themes/

wget https://github.com/PomeloOfficial/Weibo/releases/download/V3.0/Weibo-3.0.zip
unzip Weibo-3.0.zip -d /var/www/typecho/usr/themes/
wget https://cdn.typechx.com/themes/usr/uploads/2025/03/4204659085.zip
unzip 4204659085.zip -d /var/www/typecho/usr/themes/
wget https://github.com/jkjoy/typecho-theme-farallon/releases/download/0.6.3/farallon-0.6.3.zip
unzip farallon-0.6.3.zip -d /var/www/typecho/usr/themes/
chown -R www-data:www-data /var/www/typecho/usr/
chmod -R 755 /var/www/typecho/usr/

echo "🧩 配置 Nginx 虚拟主机..."
cat > /etc/nginx/sites-available/typecho <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/typecho;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/typecho /etc/nginx/sites-enabled/typecho
rm -f /etc/nginx/sites-enabled/default

echo "⚙️ 优化 PHP-FPM 配置..."
sed -i 's/^memory_limit = .*/memory_limit = 64M/' /etc/php/7.4/fpm/php.ini
sed -i 's/^pm = .*/pm = ondemand/' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/^pm.max_children = .*/pm.max_children = 3/' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/^pm.start_servers = .*/pm.start_servers = 1/' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 1/' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 2/' /etc/php/7.4/fpm/pool.d/www.conf
echo "🔄 重启服务..."
systemctl restart php7.4-fpm
systemctl restart nginx
IP=$(curl -s https://api.ip.sb/ip)
echo "✅ 部署完成！现在你可以通过服务器 IP 访问网站，开始安装 Typecho 了！"
echo "🌐 示例访问地址：http://$IP"