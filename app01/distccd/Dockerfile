# distccd 2.18.3 — CVE-2004-2687. Not a bug, a design property: the daemon
# executes whatever "compile job" a client sends, so --allow 0.0.0.0/0 means
# unauth RCE (as the distcc user). A Metasploitable2 staple
# (exploit/unix/distcc/distcc_exec) — which is why we build the same 2.18.3
# from source: modern Debian distcc 3.x carries a compiler whitelist patch
# that rejects the classic `sh -c` job.
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc make libc6-dev libpopt-dev curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN curl -sL -o distcc.tar.gz "https://snapshot.debian.org/archive/debian/20070310T000000Z/pool/main/d/distcc/distcc_2.18.3.orig.tar.gz" \
    && echo "89195c055ce49ef53a7d1bbf20ef40761ef73c68  distcc.tar.gz" | sha1sum -c - \
    && tar xzf distcc.tar.gz && rm distcc.tar.gz
WORKDIR /build/distcc-2.18.3
RUN ./configure >/dev/null && make >/dev/null

FROM debian:bookworm-slim
RUN useradd -r -m -s /bin/sh distcc
COPY --from=build /build/distcc-2.18.3/distccd /usr/local/bin/distccd
# a compile farm needs a compiler
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev libpopt0 \
    && rm -rf /var/lib/apt/lists/*
CMD ["distccd", "--daemon", "--no-detach", "--allow", "0.0.0.0/0", \
     "--port", "3632", "--user", "distcc"]
