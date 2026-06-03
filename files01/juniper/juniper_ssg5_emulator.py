#!/usr/bin/env python3
"""Juniper SSG5-Serial telnet emulator (Python 3).

TCP :23 — emulates ScreenOS 6.3.0r19.0.
Normal creds:  netscreen / netscreen
Backdoor:      CVE-2015-7755 — any username + password "<<< %s(un='%s') = %u"
Commands:      ?, get system, get config, exit
"""

import socket
import string
import threading
import time

from juniper_strings import juniper

UN_PASS_CONFIG = {('netscreen', 'netscreen')}

CVE_2015_7755_PASSWORD = "<<< %s(un='%s') = %u"


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

    def run(self):
        with _lock:
            _sessions.append(self)
        print(f'[juniper] connected {self.addr}')
        try:
            # Discard initial telnet negotiation bytes (short timeout)
            self.sock.settimeout(0.5)
            try:
                self.sock.recv(256)
            except (socket.timeout, OSError):
                pass
            self.sock.settimeout(None)

            # Login loop
            authenticated = False
            while not authenticated:
                _send(self.sock, 'Remote Management Console\n')
                _send(self.sock, 'login: ')
                username_raw = _recv(self.sock)
                if username_raw is None:
                    return
                _send(self.sock, 'password: ')
                password_raw = _recv(self.sock)
                if password_raw is None:
                    return
                username = username_raw.strip()
                password = password_raw.strip()

                if password == CVE_2015_7755_PASSWORD and username:
                    print(f'[juniper] CVE-2015-7755 backdoor login from {self.addr} (user={username!r})')
                    authenticated = True
                elif (username, password) in UN_PASS_CONFIG:
                    print(f'[juniper] login OK: {username!r} from {self.addr}')
                    authenticated = True
                else:
                    print(f'[juniper] FAILED login: {username!r}:{password!r} from {self.addr}')
                    time.sleep(5)
                    _send(self.sock, ' ### Login failed\n')

            # Command loop
            while True:
                _send(self.sock, juniper.get('PROMPT', '-> '))
                raw = _recv(self.sock)
                if raw is None:
                    break
                if raw and raw[0] not in string.printable:
                    continue
                cmd = raw.strip()
                cmd_upper = cmd.upper()
                if cmd_upper == 'EXIT':
                    break
                response = juniper.get(cmd_upper, f'               ^------unknown keyword {cmd}\n')
                _send(self.sock, response)
                if cmd:
                    print(f'[juniper] input: {cmd!r}')
        except (ConnectionResetError, BrokenPipeError, OSError):
            pass
        finally:
            try:
                self.sock.close()
            except OSError:
                pass
        print(f'[juniper] disconnected {self.addr}')
        with _lock:
            if self in _sessions:
                _sessions.remove(self)


_sessions = []
_lock = threading.Lock()

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
while True:
    try:
        srv.bind(('', 23))
        break
    except OSError:
        print('[juniper] port 23 busy, retrying in 10s')
        time.sleep(10)

srv.listen(8)
print('[juniper] SSG5 emulator listening on :23')
while True:
    _Session(*srv.accept()).start()
