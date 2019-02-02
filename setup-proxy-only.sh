#!/bin/bash
function check_root() {
        if [ ! "$(whoami)" = "root" ]
        then
            echo "Root privilege required to run this script. Rerun as root."
            exit 1
        fi
}
check_root

if [ -z "$1" ] || [ -z "$2" ]
then
    echo "Usage:   setup-proxy-only <hostname> <proxy destination>"
    echo "Example: setup-proxy-only nodejs.example.com https://127.0.0.1:12345"
    exit
fi


#certbot
echo "Fetching letsencrypt.org certificate for $1"
certbot-auto certonly --rsa-key-size 4096 --nginx -d "$1"


#nginx config
cat > "/etc/nginx/sites-available/$1.conf" <<END
server{
    server_name $1;
    server_tokens off;
    listen 80;
    listen [::]:80;

    # Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response.
    return 301 https://\$host\$request_uri;
}

server {
    server_name $1;
    server_tokens off;
    listen 443 ssl spdy;
    listen [::]:443 ssl spdy;

    location / {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header X-NginX-Proxy true;

        proxy_pass $2;
        proxy_redirect off;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

    }

    #headers
    add_header Content-Security-Policy "default-src https:";
    add_header Referrer-Policy same-origin;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-Xss-Protection "1; mode=block";
    add_header Feature-Policy "accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'none'; camera 'none'; encrypted-media 'none'; fullscreen 'none'; geolocation 'none'; gyroscope 'none'; magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture 'none'; speaker 'none'; sync-xhr 'none'; usb 'none'; vr 'none'";


    access_log  /var/log/nginx/$1-access.log;
    error_log  /var/log/nginx/$1-error.log;

    #TLS config

    # certs sent to the client in SERVER HELLO are concatenated in ssl_certificate
    ssl_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$1/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # Diffie-Hellman parameter for DHE ciphersuites
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    # modern configuration. tweak to your needs.
    ssl_protocols TLSv1.2;

    # taken from https://mozilla.github.io/server-side-tls/ssl-config-generator/
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';

    ssl_prefer_server_ciphers on;

    # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
    add_header Strict-Transport-Security "max-age=15786000; includeSubdomains; preload";

    # OCSP Stapling ---
    # fetch OCSP records from URL in ssl_certificate and cache them
    ssl_stapling on;
    ssl_stapling_verify on;

    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    ssl_ecdh_curve secp384r1;
}
END

ln -s "/etc/nginx/sites-available/$1.conf" "/etc/nginx/sites-enabled/$1.conf"

service nginx reload
service php5-fpm reload


echo "Virtual host created. Proxying $1 to $2."
