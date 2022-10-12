USER_SECRET=$1
DOMAIN=$2
IP=$(curl -Lso- https://api.ipify.org);
echo $IP

apt-get install -y apt-transport-https ca-certificates git curl wget gnupg-agent software-properties-common git nginx certbot python3-certbot-nginx

mkdir -p /opt/nginx
cd /opt/nginx

rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

ln -s $(pwd)/web.conf /etc/nginx/conf.d/web.conf
mkdir -p /etc/nginx/stream.d/ 
ln -s $(pwd)/sni-proxy.conf /etc/nginx/stream.d/sni-proxy.conf
ln -s $(pwd)/signal.conf /etc/nginx/stream.d/signal.conf

if ! grep -Fxq "include /etc/nginx/stream.d/*.conf;" /etc/nginx/nginx.conf; then
  echo "include /etc/nginx/stream.d/*.conf;">>/etc/nginx/nginx.conf;
fi

sed -i "s/defaultusersecret/$USER_SECRET/g" web.conf
sed -i "s/defaultserverip/$IP/g" web.conf
sed -i "s/defaultusersecret/$USER_SECRET/g" replace.conf
sed -i "s/defaultserverip/$IP/g" replace.conf

sed -i "s/defaultserverhost/$DOMAIN/g" web.conf
sed -i "s/defaultserverhost/$DOMAIN/g" sni-proxy.conf
certbot --nginx --register-unsafely-without-email -d $DOMAIN --non-interactive --agree-tos  --https-port 444
sed -i "s/listen 444 ssl;/listen 444 ssl http2;/" web.conf
echo "https://$DOMAIN/$USER_SECRET/">use-link

systemctl restart nginx
