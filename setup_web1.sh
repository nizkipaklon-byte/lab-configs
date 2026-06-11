#!/bin/bash
# =============================================
# Вариант 19 — WEB1 и WEB2 (RedOS)
# Запускать отдельно на каждом!
#
# WEB1: web1.hq.left — 192.168.239.105/27
# WEB2: web2.hq.left — 192.168.239.107/27
#
# Перед запуском задай переменные:
#   export NODE=web1    (или web2)
#   export MYIP=192.168.239.105   (или .107)
# =============================================

set -e

NODE="${NODE:-web1}"
MYIP="${MYIP:-192.168.239.105}"
DOMAIN="hq.left"
GW="192.168.239.97"
DNS="192.168.239.126"

echo "=== [${NODE}] Устанавливаем имя хоста ==="
hostnamectl set-hostname "${NODE}.${DOMAIN}"

echo "=== [${NODE}] Устанавливаем IP ==="
nmcli con mod "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses "${MYIP}/27" \
  ipv4.gateway "${GW}" \
  ipv4.dns "${DNS}" \
  connection.autoconnect yes
nmcli con up "Wired connection 1"

echo "=== [${NODE}] Устанавливаем пакеты ==="
dnf install -y git httpd python3-mod_wsgi
pip3 install flask

echo "=== [${NODE}] Скачиваем сайт ==="
cd /var/www/html/
git clone http://192.168.192.99:3000/Administrator/flask_win3

echo "=== [${NODE}] Настраиваем Apache ==="
cp /var/www/html/flask_win3/flask.conf /etc/httpd/conf.d/

# Патчим конфиг чтобы сайт показывал имя сервера
if [ -f /var/www/html/flask_win3/app.py ]; then
  # Добавляем имя ВМ в ответ сайта если не добавлено
  grep -q "hostname\|NODE\|WEB" /var/www/html/flask_win3/app.py \
    || sed -i "s/return/import socket; hostname=socket.gethostname(); #/1"
fi

systemctl enable --now httpd
systemctl restart httpd

echo "=== [${NODE}] Готово! Сайт доступен по http://${MYIP} ==="
