# ERROR:
# BCM: firmware Patch file not found, tried:\
# BCM: 'brcm/BCM20702A1-0a5c-21e8.hcd'
# CHECK:
sudo dmesg | grep -i bluetooth
# SOLUTION:
mkdir -p ~/Work/bin; \
cd ~/Work/bin; \
git clone https://github.com/winterheart/broadcom-bt-firmware.git; \
sudo rm /lib/firmware/brcm/BCM20702A1-0a5c-21e8.hcd 2> /dev/null; \
sudo cp ~/Work/bin/broadcom-bt-firmware/brcm/BCM20702A1-0a5c-21e8.hcd /lib/firmware/brcm/BCM20702A1-0a5c-21e8.hcd; \
cd