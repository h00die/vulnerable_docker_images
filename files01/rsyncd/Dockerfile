FROM alpine:3.20
RUN apk add --no-cache rsync
COPY rsyncd.conf /etc/rsyncd.conf
COPY share /srv/rsync
# anonymous, listable, WRITABLE module — the classic backup-server misconfig
CMD ["rsync", "--daemon", "--no-detach", "--config=/etc/rsyncd.conf"]
