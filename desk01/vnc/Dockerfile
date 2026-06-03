FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        x11vnc xvfb openbox xterm x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Weak VNC password: "password"
RUN mkdir -p /root/.vnc \
    && x11vnc -storepasswd password /root/.vnc/passwd

COPY start-vnc.sh /start-vnc.sh
RUN chmod +x /start-vnc.sh

CMD ["/start-vnc.sh"]
