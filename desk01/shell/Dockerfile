FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        socat \
    && rm -rf /var/lib/apt/lists/*

# Low-priv user the bind shell lands on (matches the looted creds theme)
RUN useradd -m -s /bin/bash jsmith

COPY start-shell.sh /start-shell.sh
RUN chmod +x /start-shell.sh

USER jsmith
CMD ["/start-shell.sh"]
