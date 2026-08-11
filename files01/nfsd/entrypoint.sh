#!/bin/bash
# NFS kernel-server entrypoint: rpcbind -> nfsd -> exportfs -> statd -> mountd.
# mountd runs in the foreground and keeps the container alive; on stop we
# drain the kernel nfsd threads so port 2049 is released back to the host.
set -e

mkdir -p /run/rpcbind

# kernel nfsd control filesystem (host kernel — container is privileged)
mount -t nfsd nfsd /proc/fs/nfsd 2>/dev/null || true

# portmapper first — nfsd/mountd/statd all register against it
rpcbind -w

# start kernel server threads (bookworm default: v3 + v4/4.1/4.2 enabled)
rpc.nfsd

exportfs -ra

# lock manager for v3 clients; fixed ports so firewalls can be deterministic
rpc.statd --no-notify --port 32765 --outgoing-port 32766 || true

# mount protocol for showmount / v3 mounts, pinned to the classic port
rpc.mountd --foreground --debug all --port 20048 &
MOUNTD_PID=$!

trap 'rpc.nfsd 0; kill $MOUNTD_PID 2>/dev/null' TERM INT
wait $MOUNTD_PID
