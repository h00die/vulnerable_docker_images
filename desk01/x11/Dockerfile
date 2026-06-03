FROM debian:bookworm-slim

# Minimal X stack: virtual framebuffer + a WM + a couple of apps so the
# exposed display actually shows something to screenshot / keylog.
RUN apt-get update && apt-get install -y --no-install-recommends \
        xvfb x11-apps x11-utils x11-xserver-utils openbox xterm \
    && rm -rf /var/lib/apt/lists/*

COPY start-x11.sh /start-x11.sh
RUN chmod +x /start-x11.sh

CMD ["/start-x11.sh"]
