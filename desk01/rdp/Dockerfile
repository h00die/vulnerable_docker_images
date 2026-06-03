FROM ubuntu:22.04

# xrdp + a lightweight desktop. Two accounts: a weak default (ubuntu/ubuntu)
# and jsmith/password123 which chains with web01 (SSH/FTP) and WordPress.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xrdp xorgxrdp xfce4 xfce4-terminal dbus-x11 sudo \
    && rm -rf /var/lib/apt/lists/* \
    && adduser xrdp ssl-cert \
    && useradd -m -s /bin/bash ubuntu 2>/dev/null || true \
    && echo 'ubuntu:ubuntu'       | chpasswd \
    && useradd -m -s /bin/bash jsmith \
    && echo 'jsmith:password123'  | chpasswd \
    && adduser jsmith sudo \
    && echo "xfce4-session" > /home/ubuntu/.xsession && chown ubuntu:ubuntu /home/ubuntu/.xsession \
    && echo "xfce4-session" > /home/jsmith/.xsession && chown jsmith:jsmith /home/jsmith/.xsession

COPY start-rdp.sh /start-rdp.sh
RUN chmod +x /start-rdp.sh

EXPOSE 3389
CMD ["/start-rdp.sh"]
