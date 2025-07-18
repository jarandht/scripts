#!/bin/bash
read -p "Enter serviceuser username: " SERVICEUSER

useradd -r -s /sbin/nologin --no-create-home $SERVICEUSER

echo $SERVICEUSER'      ALL=(ALL:ALL) NOPASSWD: /usr/bin/apt-get update, /usr/bin/dpkg --configure -a, /usr/bin/apt-get upgrade -y, /bin/systemctl reboot' | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/'$SERVICEUSER)

(sudo crontab -l -u $SERVICEUSER; echo "0 5 * * * sudo /usr/bin/apt-get update && sudo /usr/bin/dpkg --configure -a && sudo /usr/bin/apt-get upgrade -y") | sudo crontab -u $SERVICEUSER -
(sudo crontab -l -u $SERVICEUSER; echo "0 6 * * 7 sudo /bin/systemctl reboot") | sudo crontab -u $SERVICEUSER -
