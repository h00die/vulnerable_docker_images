FROM alpine:3.20
RUN apk add --no-cache tftp-hpa
COPY tftp /var/tftp
# -L standalone  -s serve /var/tftp  -c allow file creation  -p no perm checks
# (anonymous read+write, no auth — TFTP by design)
CMD ["in.tftpd", "-L", "-s", "-c", "-p", "/var/tftp"]
