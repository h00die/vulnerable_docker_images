FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        snmpd snmp \
    && rm -rf /var/lib/apt/lists/*

COPY snmpd.conf /etc/snmp/snmpd.conf
COPY snmp-secret.txt /etc/snmp/snmp-secret.txt

# Run as root so snmpd can bind port 161 (privileged port)
CMD ["snmpd", "-f", "-Lo", "-c", "/etc/snmp/snmpd.conf"]
