#!/bin/bash
yum install -y cifs-utils
cat > /root/.smbcredentials << 'CREDS'
username=svc_backup
password=P@ssw0r1d
domain=ORG
CREDS
chmod 600 /root/.smbcredentials
wget -O /root/backup.sh https://raw.githubusercontent.com/nizkipaklon-byte/lab-configs/main/backup.sh
chmod +x /root/backup.sh
echo "0 3 * * * root /root/backup.sh" >> /etc/crontab
bash /root/backup.sh
echo "Setup done"
