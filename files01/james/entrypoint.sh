#!/bin/bash
set -e

# cron daemon required for CVE-2015-7611 Cron target (writes to /etc/cron.d/)
cron

CONFIG=/opt/james/apps/james/SAR-INF/config.xml

if [ ! -f "$CONFIG" ]; then
    # James extracts its SAR on first boot; start it briefly just to unpack
    /opt/james/bin/run.sh &
    INIT_PID=$!
    until [ -f "$CONFIG" ]; do sleep 1; done
    kill $INIT_PID 2>/dev/null
    wait $INIT_PID 2>/dev/null || true
    sleep 1
fi

# Normalize admin password to root/root (default ships as !changeme!)
python3 -c "
import pathlib
p = pathlib.Path('/opt/james/apps/james/SAR-INF/config.xml')
p.write_text(p.read_text().replace('!changeme!', 'root'))
"

# Start James
/opt/james/bin/run.sh &
JAMES_PID=$!

INIT_FLAG=/opt/james/.lab_initialized

if [ ! -f "$INIT_FLAG" ]; then
    echo "[james] Waiting for admin port 4555..."
    for i in $(seq 1 60); do
        bash -c "echo >/dev/tcp/127.0.0.1/4555" 2>/dev/null && break
        sleep 2
    done
    sleep 2

    python3 - <<'EOF'
import socket, time

def read_until(s, marker, timeout=10):
    s.settimeout(0.1)
    buf = b""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            chunk = s.recv(4096)
            if chunk:
                buf += chunk
                if marker.encode() in buf:
                    return buf.decode(errors="replace")
        except socket.timeout:
            continue
    return buf.decode(errors="replace")

def drain(s, wait=0.6):
    s.settimeout(0.1)
    buf = b""
    deadline = time.time() + wait
    while time.time() < deadline:
        try:
            chunk = s.recv(4096)
            if chunk:
                buf += chunk
                deadline = time.time() + 0.2
        except socket.timeout:
            break
    s.settimeout(None)
    return buf.decode(errors="replace")

def drain(s, wait=0.6):
    s.settimeout(0.1)
    buf = b""
    deadline = time.time() + wait
    while time.time() < deadline:
        try:
            chunk = s.recv(4096)
            if chunk:
                buf += chunk
                deadline = time.time() + 0.2
        except socket.timeout:
            break
    s.settimeout(None)
    return buf.decode(errors="replace")

s = socket.socket()
s.connect(("127.0.0.1", 4555))
drain(s, 2)           # consume banner + "Login id:"

s.sendall(b"root\r\n")
drain(s)              # consume "Password:"

s.sendall(b"root\r\n")
drain(s, 1.5)         # consume welcome message

s.sendall(b"adddomain corp.local\r\n")
drain(s)

users = [
    ("jsmith",   "password123"),
    ("agarcia",  "123456"),
    ("backup",   "letmein"),
    ("trogdon",  "ttrogdon"),
    ("dmudd",    "crazypassword"),
]
for user, pw in users:
    s.sendall(f"adduser {user} {pw}\r\n".encode())
    resp = drain(s)
    print(f"[james] adduser {user}: {resp.strip()}")

s.sendall(b"quit\r\n")
s.close()
print("[james] Users seeded.")
EOF

    touch "$INIT_FLAG"
    echo "[james] Init complete."
fi

wait $JAMES_PID
