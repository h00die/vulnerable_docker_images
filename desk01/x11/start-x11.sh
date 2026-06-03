#!/bin/bash
# Deliberately insecure X11: the server listens on TCP 6000 with access control
# DISABLED. -ac is the equivalent of `xhost +` (anyone may connect to the
# display); -listen tcp opens port 6000. An attacker can then screenshot the
# display (xwd), enumerate windows (xwininfo), or log keystrokes.
set -e
export DISPLAY=:0

Xvfb :0 -screen 0 1280x800x24 -ac -listen tcp &
for i in $(seq 1 20); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.5; done

openbox &
xsetroot -solid midnightblue 2>/dev/null || true

# something on screen — a "sticky note" that leaks a credential, so an attacker
# who screenshots the open display is rewarded (chains to app01's Tomcat).
xterm -geometry 92x22+60+60 -title "sticky-note" -e bash -c \
  'printf "=== IT sticky note ===\n\ntemp tomcat manager login:\n   admin / admin123\n\n(remove after migration!)\n"; exec sleep infinity' &
xclock -geometry 140x140-20+20 &

tail -f /dev/null
