# UnrealIRCd 3.2.8.1 with the 2010 supply-chain backdoor (CVE-2010-2075):
# any raw line starting with "AB" is handed to system(). This is the genuine
# trojaned tarball from exploit-db's incident archive (the same artifact
# metasploitable3 vendors) — verified: the only system() call in the tree is
# the documented DEBUG3 macro (src/s_bsd.c:1436, include/struct.h:1382).
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc make libc6-dev curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN curl -sL -o unreal.tar.gz "https://www.exploit-db.com/apps/752e46f2d873c1679fa99de3f52a274d-Unreal3.2.8.1_backdoor.tar_.gz" \
    && echo "086708695ab75041adb1a61aaa1a86141f2548ea  unreal.tar.gz" | sha1sum -c - \
    && tar xzf unreal.tar.gz && rm unreal.tar.gz \
    && mv Unreal3.2 /src
WORKDIR /src
# Config's questions all take defaults; modern gcc needs gnu89 inline + common
RUN printf 'y\n%.0s\n' $(seq 40) | ./Config >/dev/null \
    && sed -i 's/^CFLAGS=/CFLAGS=-fgnu89-inline -fcommon /' Makefile \
    && make >/dev/null

# DPATH is compiled in as /src, so the runtime tree must live at /src too
FROM debian:bookworm-slim
RUN useradd -r -m ircd
COPY --from=build /src /src
COPY unrealircd.conf /src/unrealircd.conf
RUN chown -R ircd:ircd /src
USER ircd
WORKDIR /src
# the ircd self-daemonizes (parent exits), which would stop the container —
# tail its log in the foreground to keep it alive
CMD ["sh", "-c", "./src/ircd && tail -F /src/ircd.log"]
