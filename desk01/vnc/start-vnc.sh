#!/bin/bash
# Deliberately insecure VNC: password "password", shared, port 5900.
# Uses an internal Xvfb on display :2 (no TCP, unix socket only) so it
# doesn't conflict with the x11 service which owns :0 and port 6000.
set -e
export DISPLAY=:2

Xvfb :2 -screen 0 1024x768x24 &
for i in $(seq 1 20); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.5; done

openbox &
xsetroot -solid "#1a1a2e" 2>/dev/null || true

# Sticky note — backup SSH/FTP cred visible to anyone who screenshots the display.
xterm -geometry 72x16+50+60 -title "remote-notes" -e bash -c \
  'printf "=== Remote Mgmt Notes ===\n\nBackup sync account (web01 FTP/SSH):\n   backup / letmein\n\n(do NOT share outside IT)\n"; exec sleep infinity' &

xclock -geometry 110x110-20+20 &

exec x11vnc -display :2 -rfbauth /root/.vnc/passwd \
     -forever -rfbport 5900 -shared -quiet
