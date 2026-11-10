# hosts/punk/post-install.sh — se carga (source) al final de post-install.sh.
# shellcheck shell=bash

log "estado de TLP / baterías (revisa que los umbrales se hayan aplicado):"
sudo tlp-stat -b 2>/dev/null | sed -n '1,40p' || true
