#!/bin/bash
set -e

# cron daemon required for CVE-2015-7611 Cron target (writes to /etc/cron.d/)
cron

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

def recv_fixed(s, t=3):
    s.settimeout(t)
    buf = b""
    try:
        while True:
            chunk = s.recv(4096)
            if chunk: buf += chunk
    except: pass
    s.settimeout(None)
    return buf

s = socket.socket()
s.connect(("127.0.0.1", 4555))
banner = recv_fixed(s)
print(f"[DEBUG] banner: {repr(banner)}")

s.sendall(b"root\r\n")
r1 = recv_fixed(s)
print(f"[DEBUG] after loginid: {repr(r1)}")

s.sendall(b"root\r\n")
r2 = recv_fixed(s)
print(f"[DEBUG] after password: {repr(r2)}")

s.close()
print("[james] Debug done.")
EOF

    touch "$INIT_FLAG"
    echo "[james] Init complete."
fi

wait $JAMES_PID
