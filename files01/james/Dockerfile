FROM eclipse-temurin:8-jre-jammy

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget cron python3 \
    && rm -rf /var/lib/apt/lists/*

# Apache James 2.3.2.1 — CVE-2015-7611 path traversal → arbitrary file write
RUN wget -q https://archive.apache.org/dist/james/server/james-binary-2.3.2.1.tar.gz \
    -O /tmp/james.tar.gz \
    && tar xzf /tmp/james.tar.gz -C /opt \
    && rm /tmp/james.tar.gz \
    && mv /opt/james-2.3.2.1 /opt/james \
    && chmod +x /opt/james/bin/*.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25 110 143 4555

ENTRYPOINT ["/entrypoint.sh"]
