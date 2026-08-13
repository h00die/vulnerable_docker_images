# Elasticsearch 1.4.2 — no auth (1.x has no security layer) and dynamic
# Groovy scripting is ON by default, which is exactly what CVE-2015-1427
# (Groovy sandbox bypass → RCE) needs. Fixed in 1.4.3, so we pin 1.4.2.
FROM eclipse-temurin:8-jre
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
RUN curl -sLO https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.4.2.tar.gz \
    && echo "ae381615ec7f657e2a08f1d91758714f13d11693  elasticsearch-1.4.2.tar.gz" | sha1sum -c - \
    && tar xzf elasticsearch-1.4.2.tar.gz \
    && rm elasticsearch-1.4.2.tar.gz \
    && mv elasticsearch-1.4.2 elasticsearch
COPY elasticsearch.yml /opt/elasticsearch/config/elasticsearch.yml
COPY seed.sh /opt/seed.sh
RUN useradd -r -m -s /bin/bash elastic \
    && chown -R elastic:elastic /opt/elasticsearch \
    && chmod +x /opt/seed.sh
USER elastic
CMD ["/opt/seed.sh"]
