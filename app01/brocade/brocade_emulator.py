#!/usr/bin/env python3
"""Brocade FWS624 / ICX6450 telnet emulator (Python 3).

TCP :23 — emulates IronWare 7.2 or 7.4.
show config creds:          username/password, ttrogdon/ttrogdon, dmudd/crazypassword
show running-config creds:  TopDogUser/mystery
type 'switchversion' to toggle between 7.2 and 7.4 responses.
"""

import re
import socket
import string
import threading
import time

# Telnet control bytes
IAC  = b'\xff'
WILL = b'\xfb'
WONT = b'\xfc'
DO   = b'\xfd'
DONT = b'\xfe'
ECHO             = b'\x01'
SUPPRESS_GO_AHEAD = b'\x03'

# Sent on connect so clients enter character mode and nmap fingerprints as telnet
TELNET_INIT = (
    IAC + WILL + ECHO +
    IAC + WILL + SUPPRESS_GO_AHEAD +
    IAC + DO   + SUPPRESS_GO_AHEAD
)

# Strip any IAC sequence (2- or 3-byte) from received data
_IAC_RE = re.compile(b'\xff[\xfb\xfc\xfd\xfe][\x00-\xff]|\xff\xff|\xff[\xf0-\xfa][\x00-\xff]*\xff\xf0')

PROMPT = "brocade@FWS624>"
ENABLED_PROMPT = "brocade@FW624#"

UN_PASS_CONFIG = {
    ('username', 'password'): '',
    ('ttrogdon', 'ttrogdon'): 5,
    ('dmudd', 'crazypassword'): 4,
}
UN_PASS_RUNNING = {
    ('TopDogUser', 'mystery'): '',
}

BANNER = b"""\
Warning Notification!!!
This system is to be used by authorized users only for the purpose of
conducting official company work. Any activities conducted on this system may
be monitored and/or recorded and there is no expectation of privacy while
using this system. All possible abuse and criminal activity may be handed
over to the proper law enforcement officials for investigation and
prosecution. Use of this system implies consent to all of the conditions
stated within this Warning Notification."""

SHOW_HELP = b"""\
  enable            Enter Privileged mode
  ping              Ping IP node
  show              Display system information
  stop-traceroute   Stop current TraceRoute
  traceroute        TraceRoute to IP Node"""

SHOW_VERSION_72 = b"""\
  Copyright (c) 1996-2010 Brocade Communications Systems, Inc.
    UNIT 1: compiled on Feb 16 2012 at 20:20:31 labeled as FGSL07202f
                (3172304 bytes) from Secondary FGSL07202f.bin
        SW: Version 07.2.02fT7e1
  Boot-Monitor Image size = 416213, Version:05.0.00T7e5 (Fev2)
  HW: Stackable FWS624
==========================================================================
UNIT 1: SL 1: FastIron WS 624 24-port Management Module
         Serial  #: AN11111111
         License: FWS_BASE_L3_SOFT_PACKAGE   (LID: aaAAAAAAAA)
         P-ENGINE  0: type D814, rev 01
==========================================================================
  400 MHz Power PC processor 8248 (version 130/2014) 66 MHz bus
  512 KB boot flash memory
30720 KB code flash memory
  256 MB DRAM
STACKID 1  system uptime is 2 days 4 hours 25 minutes 10 seconds
The system : started=warm start  reloaded=by "reload"
"""

SHOW_VERSION_74 = b"""\
  Copyright (c) 1996-2012 Brocade Communications Systems, Inc. All rights reserved.
    UNIT 1: compiled on Oct 3 2012 at 08:42:29 labeled as ICX64S07400b
                (10371776 bytes) from Primary ICX64S07400b.bin
        SW: Version 07.4.00bT311
  Boot-Monitor Image size = 776680, Version:07.4.01T310 (kxz07401)
  HW: Stackable ICX6450-24
==========================================================================
UNIT 1: SL 1: ICX6450-24 24-port Management Module
         Serial #: BAA1111A11A
         License: BASE_SOFT_PACKAGE (LID: aaaAAAAaAAa)
         P-ENGINE 0: type DEF0, rev 01
==========================================================================
UNIT 1: SL 2: ICX6450-SFP-Plus 4port 40G Module
==========================================================================
  800 MHz ARM processor ARMv5TE, 400 MHz bus
  65536 KB flash memory
  512 MB DRAM
STACKID 1 system uptime is 78 days 2 hours 54 minutes 7 seconds
The system : started=cold start
"""

V72_CONFIG = """\
!
Startup-config data location is flash memory
!
Startup configuration:
!
ver 07.2.02fT7e1
!
module 1 fwsl00m-24-port-copper-base-module
!
tftp disable
!
!
vlan 1 name DEFAULT-VLAN by port
!
vlan 100 by port
!
system-max hw-ip-route-tcam 64
!
aaa authentication web-server default local
aaa authentication login default local
boot sys fl sec
console timeout 10
enable super-user-password .....
hostname brocade
ip dhcp-server enable
!
ip dhcp-server pool bro
 dns-server 192.168.50.1
 domain-name groupbro
 lease 1 0 0
 network 192.168.50.0 255.255.255.0
!
ip route 0.0.0.0 0.0.0.0 10.210.10.65
!
no ip source-route
logging facility local4
no logging buffered debugging
logging console
no telnet server
telnet server enable vlan 1
%s
password-change any
cdp run
fdp run
snmp-server community ..... ro 15
clock summer-time
clock timezone us Eastern
no web-management hp-top-tools
no web-management http
banner motd ^C
**********************************************^C
WARNING .... WARNING .... WARNING^C
You have entered into a restricted site.^C
This system is to be accessed only by^C
specifically authorized personnel.^C
**********************************************^C
^C
!
no port bootp
!
access-list 15 permit host 10.1.2.32
access-list 15 deny any log
!
ip ssh  idle-time 10
!
end
"""

V74_CONFIG = """\
!
Startup-config data location is flash memory
!
Startup configuration:
!
ver 07.4.00bT311
!
stack unit 1
module 1 icx6450-24-port-management-module
module 2 icx6450-sfp-plus-4port-40g-module
!
vlan 1 name DEFAULT-VLAN by port
!
vlan 901 name Test by port
tagged ethe 1/1/1 to 1/1/12
untagged ethe 1/1/12 to 1/1/24
!
aaa authentication enable default local
aaa authentication login default local
console timeout 10
enable super-user-password .....
enable aaa console
hostname bro-switch
ip address 10.1.2.1 255.255.255.224
no ip dhcp-client enable
%s
no snmp-server
no snmp-server community public ro
no web-management http
banner exec ^C
Warning Notification!!!^C
This system is to be used by authorized users only.^C
^C
!
ssh access-group 10
interface ethernet 1/1/1
speed-duplex 1000-full-master
!
interface ethernet 1/1/2
speed-duplex 1000-full-master
!
access-list 10 permit 10.1.2.1 0.0.0.24
access-list 10 deny any log
!
ip ssh timeout 30
ip ssh idle-time 10
!
end
"""


def _send(sock, data):
    if isinstance(data, str):
        data = data.encode('latin-1', errors='replace')
    try:
        sock.sendall(data)
    except OSError:
        pass


def _recv(sock):
    try:
        data = sock.recv(1024)
    except OSError:
        return None
    if not data:
        return None
    return data.decode('latin-1', errors='ignore')


class _Session(threading.Thread):
    def __init__(self, conn, addr):
        super().__init__(daemon=True)
        self.sock = conn
        self.addr = addr
        self.enabled = False
        self.version = "7.2"

    def _build_cred_list(self, cred_map):
        lines = []
        for (un, _p), priv in cred_map.items():
            if priv:
                lines.append(f"username {un} privilege {priv} password .....")
            else:
                lines.append(f"username {un} password .....")
        return "\n".join(lines)

    def run(self):
        with _lock:
            _sessions.append(self)
        print(f'[brocade] connected {self.addr}')
        _send(self.sock, TELNET_INIT)
        _send(self.sock, BANNER)
        try:
            while True:
                prompt = ('\n' + ENABLED_PROMPT) if self.enabled else ('\n' + PROMPT)
                _send(self.sock, prompt)
                raw = _recv(self.sock)
                if raw is None:
                    break
                # strip telnet IAC sequences before processing
                raw = _IAC_RE.sub(b'', raw.encode('latin-1')).decode('latin-1', errors='ignore')
                if not cmd:
                    continue
                cmd_upper = cmd.upper()

                if cmd_upper in ('QUIT', 'LOGOUT'):
                    break
                elif cmd_upper == 'EXIT':
                    if self.enabled:
                        self.enabled = False
                    else:
                        break
                elif cmd_upper == 'SWITCHVERSION':
                    self.version = "7.4" if self.version == "7.2" else "7.2"
                    print(f'[brocade] version → {self.version}')
                elif cmd_upper in ('SHOW CONFIG', 'SHOW RUNNING-CONFIG'):
                    cred_map = UN_PASS_CONFIG if cmd_upper == 'SHOW CONFIG' else UN_PASS_RUNNING
                    template = V72_CONFIG if self.version == "7.2" else V74_CONFIG
                    _send(self.sock, template % self._build_cred_list(cred_map))
                elif cmd_upper == 'ENABLE':
                    _send(self.sock, 'User Name: ')
                    un_raw = _recv(self.sock)
                    if un_raw is None:
                        break
                    un = un_raw.strip()
                    if un.upper() == 'LOGOUT':
                        break
                    _send(self.sock, 'Password: ')
                    pw_raw = _recv(self.sock)
                    if pw_raw is None:
                        break
                    pw = pw_raw.strip()
                    if pw.upper() == 'LOGOUT':
                        break
                    if (un, pw) in UN_PASS_CONFIG or (un, pw) in UN_PASS_RUNNING:
                        self.enabled = True
                    else:
                        _send(self.sock, 'Error - Incorrect username or password.')
                elif cmd_upper == '?':
                    _send(self.sock, SHOW_HELP)
                elif cmd_upper == 'SHOW VERSION':
                    _send(self.sock, SHOW_VERSION_72 if self.version == "7.2" else SHOW_VERSION_74)
                else:
                    _send(self.sock, f'Invalid input -> {cmd}\nType ? for a list')

                if cmd:
                    print(f'[brocade] input: {cmd!r}')
        except (ConnectionResetError, BrokenPipeError, OSError):
            pass
        finally:
            try:
                self.sock.close()
            except OSError:
                pass
        print(f'[brocade] disconnected {self.addr}')
        with _lock:
            _sessions.discard(self)


_sessions = set()
_lock = threading.Lock()

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
while True:
    try:
        srv.bind(('', 23))
        break
    except OSError:
        print('[brocade] port 23 busy, retrying in 30s')
        time.sleep(30)

srv.listen(8)
print('[brocade] emulator listening on :23')
while True:
    _Session(*srv.accept()).start()
