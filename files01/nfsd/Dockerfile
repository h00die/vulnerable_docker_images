FROM debian:bookworm-slim

# nfs-kernel-server pulls in nfs-common (rpc.statd) and rpcbind
RUN apt-get update && apt-get install -y --no-install-recommends \
        nfs-kernel-server rpcbind \
    && rm -rf /var/lib/apt/lists/*

# Deliberately insecure export — this is the lab's vulnerable service.
# fsid=0 keeps it reachable as NFSv4 pseudoroot ("/") AND as v3 "/data".
COPY exports /etc/exports

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Kernel-side requirements (on the VM host, not here):
#   sudo modprobe nfs nfsd      # compose runs this container privileged + host net
ENTRYPOINT ["/entrypoint.sh"]
