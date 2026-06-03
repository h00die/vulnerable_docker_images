#!/bin/bash
# web01 SSH startup. The image already ships root/root (kept). This adds the
# extra accounts that the loot on files01 points to, so cracked/leaked creds
# actually log in here.
set -e
mkdir -p /var/run/sshd

add_user() {
  local u="$1" p="$2"
  id "$u" >/dev/null 2>&1 || useradd -m -s /bin/bash "$u"
  echo "$u:$p" | chpasswd
}

add_user jsmith  password123    # matches web01-shadow.bak (sha512crypt)
add_user agarcia 123456         # matches wp_users_dump.sql (md5)
add_user backup  letmein        # matches wp_users_dump.sql (md5)

exec /usr/sbin/sshd -D
