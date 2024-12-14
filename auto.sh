#!/bin/bash

function install_dependencies() {
    echo "Установка необходимых пакетов..."
    apt update && apt upgrade -y
    apt install -y curl wget unzip git nodejs npm certbot docker docker-compose mariadb-server nginx php-fpm php-mbstring php-xml php-bcmath redis-server cron
    systemctl enable --now docker mariadb php8.2-fpm redis-server cron
}

function setup_database() {
    echo "Настройка базы данных..."
    read -p "Введите имя базы данных (например, jexactyl): " db_name
    read -p "Введите пользователя базы данных (например, jexactyl_user): " db_user
    read -s -p "Введите пароль для базы данных: " db_pass
    echo

    mysql -u root -e "CREATE DATABASE $db_name;"
    mysql -u root -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    echo "База данных настроена."
}

function download_jexactyl() {
    echo "Загрузка последней версии Jexactyl..."
    mkdir -p /var/www/jexactyl
    curl -L https://github.com/jexactyl/jexactyl/releases/latest/download/jexactyl.tar.gz -o jexactyl.tar.gz
    tar -xvf jexactyl.tar.gz -C /var/www/jexactyl --strip-components=1
    rm jexactyl.tar.gz
    cd /var/www/jexactyl
    npm install
}

function configure_panel() {
    echo "Настройка панели Jexactyl..."
    cd /var/www/jexactyl
    cp .env.example .env
    read -p "Введите URL панели (например, http://yourdomain.com): " panel_url
    sed -i "s|APP_URL=.*|APP_URL=$panel_url|g" .env
    read -p "Введите настройки базы данных (имя, пользователь, пароль): " db_name db_user db_pass
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=$db_name|g" .env
    sed -i "s|DB_USERNAME=.*|DB_USERNAME=$db_user|g" .env
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$db_pass|g" .env
    php artisan key:generate --force
    php artisan migrate --seed --force
}

function configure_nginx_no_ssl() {
    echo "Настройка Nginx для работы без SSL..."
    read -p "Введите доменное имя или IP для панели (например, yourdomain.com или 192.168.1.1): " panel_url

    cat > /etc/nginx/sites-available/panel.conf <<EOL
# Substitua o <domain> pelo nome do seu dominio ou seu IP
server {
    listen 80;
    server_name $panel_url;

    root /var/www/jexactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/jexactyl.app-error.log error;

    # Isso permite uploads de arquivos maiores e tempos de execução de script mais longos
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ .php$ {
        fastcgi_split_path_info ^(.+.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M 
 post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /.ht {
        deny all;
    }
}
EOL

    ln -s /etc/nginx/sites-available/panel.conf /etc/nginx/sites-enabled/
    systemctl restart nginx
    echo "Nginx успешно настроен для работы без SSL!"
}

function setup_ssl() {
    echo "Настройка SSL..."
    read -p "Введите доменное имя для SSL: " domain
    certbot certonly --standalone -d "$domain"
    echo "SSL сертификаты установлены."
    echo "Настройка nginx для работы с SSL..."
    cat > /etc/nginx/sites-available/panel.conf <<EOL
# Substitua o $domain pelo nome do seu dominio ou seu IP
server {
    listen 80;
    server_name $domain;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    root /var/www/jexactyl/public;
    index index.php;

    access_log /var/log/nginx/jexactyl.app-access.log;
    error_log  /var/log/nginx/jexactyl.app-error.log error;

    # Isso permite uploads de arquivos maiores e tempos de execução de script mais longos
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # Configuração do SSL
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ .php$ {
        fastcgi_split_path_info ^(.+.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M 
 post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /.ht {
        deny all;
    }
}
EOL

    ln -s /etc/nginx/sites-available/panel.conf /etc/nginx/sites-enabled/
    systemctl restart nginx
    echo "SSL успешно настроен."
}

function set_permissions() {
    echo "Настройка прав доступа..."
    chown -R www-data:www-data /var/www/jexactyl/*
    echo "Права доступа успешно настроены!"
}

function create_panel_service() {
    echo "Создание сервиса для Jexactyl Queue Worker..."
    cat > /etc/systemd/system/panel.service <<EOL
# Jexactyl Queue Worker File
# ----------------------------------

[Unit]
Description=Jexactyl Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/jexactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL

    systemctl enable --now panel.service
    systemctl enable --now redis-server
    echo "Сервис для Queue Worker создан и активирован!"
}

function uninstall_jexactyl() {
    echo "Удаление Jexactyl..."
    systemctl stop nginx mariadb redis-server
    rm -rf /var/www/jexactyl
    rm /etc/nginx/sites-enabled/panel.conf
    rm /etc/nginx/sites-available/panel.conf
    systemctl restart nginx
    echo "Jexactyl успешно удален."
}

while true; do
    echo "Выберите действие:"
    echo "1) Установка без SSL"
    echo "2) Установка с SSL"
    echo "3) Удаление Jexactyl"
    read -p "Введите номер: " choice

    case $choice in
        1)
            install_dependencies
            setup_database
            download_jexactyl
            configure_panel
            create_panel_service
            set_permissions
            configure_nginx_no_ssl
            echo "Установка завершена! Панель доступна по адресу: http://<ваш_IP или домен>"
            ;;
        2)
            install_dependencies
            setup_database
            download_jexactyl
            configure_panel
            create_panel_service
            set_permissions
            setup_ssl
            echo "Установка завершена! Панель доступна по адресу: https://<ваш_домен>"
            ;;
        3)
            uninstall_jexactyl
            ;;
        *)
            echo "Неверный выбор, попробуйте снова."
            ;;
    esac
done