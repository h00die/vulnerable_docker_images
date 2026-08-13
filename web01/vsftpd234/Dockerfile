# vsftpd 2.3.4 with a reimplementation of the 2011 supply-chain backdoor
# (CVE-2011-2523): any FTP command line containing ":)" spawns a root shell
# listener on 6200. Built from the *clean* Debian snapshot source (sha1
# verified) plus our own backdoor.patch — not from the trojaned tarball.
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc make libc6-dev libcrypt-dev curl ca-certificates patch \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN curl -sLO "https://snapshot.debian.org/archive/debian/20110905T213546Z/pool/main/v/vsftpd/vsftpd_2.3.4.orig.tar.gz" \
    && echo "b774cc6b4c50e20f4fe9ca7f6aa74169ce7fe5ea  vsftpd_2.3.4.orig.tar.gz" | sha1sum -c - \
    && tar xzf vsftpd_2.3.4.orig.tar.gz
COPY backdoor.patch /src/backdoor.patch
RUN patch -d vsftpd-2.3.4 -p1 < /src/backdoor.patch \
    && sed -i 's|`./vsf_findlibs.sh`|`./vsf_findlibs.sh` -lcrypt|' vsftpd-2.3.4/Makefile \
    && make -C vsftpd-2.3.4 -j"$(nproc)"

FROM debian:bookworm-slim
COPY --from=build /src/vsftpd-2.3.4/vsftpd /usr/local/sbin/vsftpd
COPY vsftpd.conf /etc/vsftpd.conf
# lab user (same looted creds as the rest of web01) + dirs vsftpd needs
RUN useradd -m -s /bin/bash jsmith && echo 'jsmith:password123' | chpasswd \
    && mkdir -p /usr/share/empty /var/ftp
CMD ["/usr/local/sbin/vsftpd", "/etc/vsftpd.conf"]
