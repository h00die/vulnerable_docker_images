# Shellshock (CVE-2014-6271): unpatched bash 4.3 built from source (none of
# the official patch series applied) behind Apache mod_cgid. Any CGI env var
# (User-Agent, Referer, ...) carrying "() { :; };" executes at shell startup.
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc make libc6-dev curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN curl -sO https://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz \
    && echo "45ac3c5727e7262334f4dfadecdf601b39434e84  bash-4.3.tar.gz" | sha1sum -c - \
    && tar xzf bash-4.3.tar.gz \
    && cd bash-4.3 && ./configure --prefix=/opt/bash43 >/dev/null \
    && make -j"$(nproc)" >/dev/null && make install >/dev/null

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends apache2 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/bash43 /opt/bash43
COPY status.cgi /usr/lib/cgi-bin/status
RUN chmod +x /usr/lib/cgi-bin/status \
    && a2enmod cgid \
    && sed -i 's/^Listen 80$/Listen 8082/' /etc/apache2/ports.conf
CMD ["apachectl", "-D", "FOREGROUND"]
