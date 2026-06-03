#!/usr/bin/env bash
#
# docker_start_instance.sh — bring a single lab box up (or down/restart/...).
#
# Usage:
#   ./docker_start_instance.sh <box> [action]
#     box     web01 | files01 | app01 | desk01
#     action  up (default) | down | restart | logs | status
#
# Examples:
#   ./docker_start_instance.sh web01           # start web01
#   ./docker_start_instance.sh desk01          # build + start desk01
#   ./docker_start_instance.sh files01 down    # stop files01
#   ./docker_start_instance.sh app01 logs      # tail app01 logs
#
set -euo pipefail

BOXES=(web01 files01 app01 desk01)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

err()  { printf '\033[31m[!]\033[0m %s\n' "$*" >&2; }
info() { printf '\033[36m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[~]\033[0m %s\n' "$*"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <box> [action]

  box     one of: ${BOXES[*]}
  action  up (default) | down | restart | logs | status
EOF
}

# ---- args ----
BOX="${1:-}"
ACTION="${2:-up}"

if [[ -z "$BOX" || "$BOX" == "-h" || "$BOX" == "--help" ]]; then usage; exit 1; fi
if ! printf '%s\n' "${BOXES[@]}" | grep -qx "$BOX"; then
  err "unknown box '$BOX'"; usage; exit 1
fi

BOX_DIR="$SCRIPT_DIR/$BOX"
[[ -f "$BOX_DIR/docker-compose.yml" ]] || { err "no docker-compose.yml in $BOX_DIR"; exit 1; }

# ---- docker / compose detection ----
command -v docker >/dev/null 2>&1 || { err "docker not found — install Docker first (see README)."; exit 1; }
if docker compose version >/dev/null 2>&1; then
  DC=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  DC=(docker-compose)
else
  err "docker compose plugin not found (see README)."; exit 1
fi

cd "$BOX_DIR"

# ---- non-up actions ----
case "$ACTION" in
  down)      info "stopping $BOX"; "${DC[@]}" down; ok "$BOX stopped"; exit 0 ;;
  restart)   info "restarting $BOX"; "${DC[@]}" restart; "${DC[@]}" ps; exit 0 ;;
  logs)      exec "${DC[@]}" logs -f ;;
  status|ps) exec "${DC[@]}" ps ;;
  up)        : ;;   # handled below
  *)         err "unknown action '$ACTION'"; usage; exit 1 ;;
esac

# ---- per-box pre-flight (up only) ----
port_busy() { command -v ss >/dev/null 2>&1 && ss -H -ltn "sport = :$1" 2>/dev/null | grep -q .; }

BUILD=()
case "$BOX" in
  web01)
    BUILD=(--build)   # werkzeug service builds from local Dockerfile
    if port_busy 22; then
      warn "port 22 is already in use — the VM's own sshd probably has it."
      warn "move host sshd to another port so the vulnerable SSH can bind 22 (see README)."
    fi
    if grep -q "REPLACE_WITH_WEB01_VM_IP" docker-compose.yml; then
      warn "FTP ADDRESS still a placeholder in web01/docker-compose.yml —"
      warn "passive FTP transfers fail until you set it to this VM's IP."
    fi
    ;;
  files01)
    BUILD=(--build)   # juniper service builds from local Dockerfile
    if ! lsmod 2>/dev/null | grep -qw nfsd; then
      info "loading NFS kernel modules (nfs, nfsd)"
      if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        modprobe nfs nfsd 2>/dev/null || warn "modprobe failed — load nfs/nfsd manually"
      elif command -v sudo >/dev/null 2>&1; then
        sudo modprobe nfs nfsd 2>/dev/null || warn "modprobe failed — load nfs/nfsd manually"
      else
        warn "no root/sudo to load nfs modules — NFS may not start"
      fi
    fi
    ;;
  app01)
    BUILD=(--build)   # brocade service builds from local Dockerfile
    ;;
  desk01)
    BUILD=(--build)   # x11 + rdp images build from local Dockerfiles
    ;;
esac

# ---- bring it up ----
info "starting $BOX"
"${DC[@]}" up -d "${BUILD[@]}"
echo
"${DC[@]}" ps
echo

# ---- next steps ----
case "$BOX" in
  web01)   ok "DVWA: open http://<this-vm-ip>/setup.php and click Create/Reset Database (admin/password)"
           ok "Werkzeug debug console: http://<this-vm-ip>:5000/crash  (PIN: 1234)" ;;
  files01) ok "Up. Try from Kali:  showmount -e <this-vm-ip>"
           ok "Juniper SSG5 telnet: telnet <this-vm-ip>  (netscreen/netscreen or CVE-2015-7755 backdoor)" ;;
  app01)   ok "Finish the WordPress wizard at http://<this-vm-ip>/ , then seed extra logins:"
           echo "    docker exec -i mysql mysql -uroot -proot wordpress < wp_seed_users.sql"
           ok "Brocade telnet: telnet <this-vm-ip>  (username/password, ttrogdon/ttrogdon, dmudd/crazypassword)" ;;
  desk01)  ok "X11 on :6000 (open), RDP on :3389 (ubuntu/ubuntu), VNC on :5900 (password: password)."
           ok "If RDP doesn't answer on first boot:  ${DC[*]} logs rdp  (then: ${DC[*]} restart rdp)" ;;
esac
