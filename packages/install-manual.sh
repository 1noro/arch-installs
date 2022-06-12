#!/bin/bash

# yt-dlp (https://github.com/yt-dlp/yt-dlp)
# subsituto de yt-dowloander
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp


# obs-stuido in gnome-wayland full featured
# (https://wiki.archlinux.org/title/Screen_capture#Screencasting)
sudo pacman -S --noconfirm obs-studio v4l2loopback-dkms && \
sudo modprobe v4l2loopback exclusive_caps=1 card_label=VirtualVideoDevice
# comprobaciónes:
# v4l2-ctl --list-devices
# mpv av://v4l2:/dev/video0
# test: https://mozilla.github.io/webrtc-landing/gum_test.html
