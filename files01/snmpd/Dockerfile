FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        snmpd snmp libcap2-bin \
    && rm -rf /var/lib/apt/lists/*

# Allow snmpd to bind port 161 (< 1024) without needing --privileged at runtime
RUN setcap cap_net_bind_service=+ep /usr/sbin/snmpd

COPY snmpd.conf /etc/snmp/snmpd.conf
COPY snmp-secret.txt /etc/snmp/snmp-secret.txt

CMD ["snmpd", "-f", "-Lo", "-c", "/etc/snmp/snmpd.conf"]
