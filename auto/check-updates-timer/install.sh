#!/bin/bash
# run as ROOT
# Timer type:
# https://wiki.archlinux.org/index.php/Systemd_(Espa%C3%B1ol)/Timers_(Espa%C3%B1ol)#Ejemplos
# rt - Real time
# m  - Monolitic
TIMER_TYPE="rt"
cp my-check-updates.service /etc/systemd/system/my-check-updates.service
cp my-check-updates-rt.timer "/etc/systemd/system/my-check-updates-$TIMER_TYPE.timer"
cp my-check-updates.sh /opt/my-check-updates.sh
chmod +x /opt/my-check-updates.sh
systemctl enable "my-check-updates-$TIMER_TYPE.timer"
echo "# INFO: Necesitas riniciar el sistema para aplicar los cambios."
