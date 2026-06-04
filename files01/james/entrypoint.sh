#!/bin/bash
set -e

# cron daemon required for CVE-2015-7611 Cron target (writes to /etc/cron.d/)
cron

# Start James
/opt/james/bin/run.sh &
JAMES_PID=$!

INIT_FLAG=/opt/james/var/.lab_initialized

if [ ! -f "$INIT_FLAG" ]; then
    echo "[james] Waiting for admin port 4555..."
    for i in $(seq 1 60); do
        bash -c "echo >/dev/tcp/127.0.0.1/4555" 2>/dev/null && break
        sleep 2
    done
    sleep 2

    python3 - <<'EOF'
import socket, time

def cmd(s, line):
    s.sendall((line + "\r\n").encode())
    time.sleep(0.4)
    return s.recv(4096).decode(errors="replace")

s = socket.socket()
s.connect(("127.0.0.1", 4555))
time.sleep(0.5)
s.recv(4096)  # banner

cmd(s, "login root root")
cmd(s, "adddomain corp.local")

users = [
    ("jsmith",   "password123"),
    ("agarcia",  "123456"),
    ("backup",   "letmein"),
    ("trogdon",  "ttrogdon"),
    ("dmudd",    "crazypassword"),
]
for user, pw in users:
    resp = cmd(s, f"adduser {user} {pw}")
    print(f"[james] adduser {user}: {resp.strip()}")

cmd(s, "quit")
s.close()
print("[james] Users seeded.")
EOF

    touch "$INIT_FLAG"
    echo "[james] Init complete."
fi

wait $JAMES_PID
