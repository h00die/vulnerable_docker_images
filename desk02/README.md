# desk02 — unpatched Windows 7 workstation (VM-in-container)

desk02 is the lab's Windows box: a full, never-patched Windows 7 Ultimate VM
run under QEMU inside a container (`dockurr/windows`). The guest has its **own
kernel**, which is the whole point — it's the only way to lab kernel-mode
Windows CVEs (MS17-010, BlueKeep) on a Linux docker host.

**Why not `microsoft/windows`?** That repo is the official *Windows container
base image* — it only starts on a Windows docker daemon (a Linux host cannot
run it at all), and Windows containers share the host kernel, so no
image-level config can ever make them MS17-010-exploitable.

## Provision the desk02 VM (it's new)

1. Minimal Ubuntu Server VM like the others (Docker install steps in the root
   README), but sized bigger — it hosts a whole VM: **4 GB RAM, 4 vCPU,
   40+ GB disk**.
2. **No nested virtualization needed.** This lab's ESXi CPUs can't expose
   `/dev/kvm`, so the compose deliberately sets `KVM: "N"` and the guest runs
   under QEMU **TCG software emulation** (~10x slower). Plan for it: expect
   the unattended install to take an hour or more and regular boots several
   minutes. Once booted, the box idles and answers SMB/RDP fine — that's all
   scanner/exploit modules need. Snapshot the desk02 VM right after the first
   install finishes so you never sit through it twice.
3. Internet on first `up` — it downloads ~3.1 GB of Windows 7 eval media.
4. Deploy: `./docker_start_instance.sh desk02` from the lab root, or
   `cd desk02 && docker compose up -d`.

## First boot

Watch `http://<desk02-ip>:8006` — the unattended install runs (an hour+ under
TCG — start it and walk away), then `oem/install.bat` fires (RDP on + NLA off,
weak users, firewall off, anonymous read-only `C:\` share) and the box reboots
once more. After that it stays up
like any other lab box. Snapshot the desk02 VM once the install finishes so
you never sit through it again.

Default login (RDP or the web console): `Docker` / `admin`.
Added by the softener: `lab_backdoor` / `Passw0rd!` (administrators) and
`svc_backup` / `backup123`. The softener also sets
`LocalAccountTokenFilterPolicy=1`, so `Docker`/`admin` drives SMB-pipe
tooling (`impacket-atexec`/`smbexec`, `psexec` modules) without a desktop —
wmiexec won't traverse the NAT though (DCOM needs 135 + dynamic ports).

`./data/` holds the VM disk — it's gitignored; never commit it.

## Targets

| Port         | Service                  | Modules                                                                                                                                                                 |
|--------------|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 445/tcp      | SMB, no auth             | `auxiliary/scanner/smb/smb_ms17_010`, `exploit/windows/smb/ms17_010_eternalblue`, `exploit/windows/smb/ms17_010_psexec`, `auxiliary/scanner/smb/smb_login` (weak users) |
| 445/tcp      | SMB `C` share, anonymous | `smbclient -N //desk02-ip/C` (browse C:), `auxiliary/scanner/smb/smb_enumshares`, `auxiliary/scanner/smb/smb_enumusers`                                                 |
| 3389 tcp/udp | RDP, NLA off             | `auxiliary/scanner/rdp/cve_2019_0708_bluekeep`, `auxiliary/scanner/rdp/rdp_scanner`                                                                                     |

```bash
# smoke test from Kali once it's up:
msfconsole -q -x 'use auxiliary/scanner/smb/smb_ms17_010; set RHOSTS <desk02-ip>; run; exit'
```

## Why `SAMBA: "N"` in the compose

dockur runs its own Samba inside the container (the `\\host.lan\Data`
host-share feature) and carves **445/139 out of the guest DNAT chain** to
feed it. With it enabled, published `445:445` is answered by dockur's Samba —
never by Windows — so SMB scans/modules see nothing (3389/8006 look fine,
which is confusing). `SAMBA: "N"` disables that; every published port except
the console (8006/5900) then DNATs straight into the guest. The lab doesn't
use the host-share feature, so nothing is lost.

For an **already-running** instance without recreating the container (takes
effect immediately, guest stays up):

```bash
docker exec windows iptables -t nat -D QEMU_DNAT -p tcp --dport 445 -j RETURN
docker exec windows iptables -t nat -D QEMU_DNAT -p tcp --dport 139 -j RETURN
```

Those rules return on container restart unless `SAMBA: "N"` is set.

Want the guest directly on the LAN (its own IP, no port mapping at all)?
Switch the compose to the macvlan network from the dockur README ("assign an
individual IP address to the container").

## Variants — swap `VERSION`

- `"xp"` — Windows XP Pro, 0.6 GB: adds MS08-067
  (`exploit/windows/smb/ms08_067_netapi`) and the XP-era netapi/DCOM classics
- `"2003"` — Server 2003, 0.6 GB
- `"11"` / `"2022"` / … — modern, **patched** builds: config-attack practice
  only (kernel CVEs are fixed in these)

## Isolation

Evaluation media on an isolated lab network only — the softener turns the
firewall off, and an unpatched Win7 with SMBv1 will be auto-owned by anything
that touches 445. It must never sit on anything routable to the internet or
production.
