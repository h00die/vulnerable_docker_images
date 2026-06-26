#!/usr/bin/env python3
"""
Generate browser credential profiles for jsmith's home directory.
Run once from this directory:  python3 generate_profiles.py

Produces:
  home/jsmith/.config/google-chrome/Default/Login Data   (Chrome v10, peanuts key)
  home/jsmith/.config/chromium/Default/Login Data        (Chromium v10, peanuts key)
  home/jsmith/.mozilla/firefox/<profile>/key4.db         (NSS, no master password)
  home/jsmith/.mozilla/firefox/<profile>/logins.json     (NSS SDR encrypted)

Students decrypt with:
  Chrome/Chromium — LaZagne, HackBrowserData, or any v10-aware script
  Firefox         — firefox_decrypt.py, firepwd.py, LaZagne
"""

import os, sys, sqlite3, json, base64, secrets, datetime, ctypes, ctypes.util

try:
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
    from cryptography.hazmat.primitives import hashes, padding as sym_padding
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    from cryptography.hazmat.backends import default_backend
except ImportError:
    sys.exit("pip install cryptography")

BASE   = os.path.dirname(os.path.abspath(__file__))
JSMITH = os.path.join(BASE, 'home/jsmith')

LOGINS = [
    # (origin_url, username, password, signon_realm)
    ('http://mail.corp.local/',        'jsmith',            'password123',   'http://mail.corp.local/'),
    ('http://intranet.corp.local/',    'jsmith@corp.local', 'Summer2023!',   'http://intranet.corp.local/'),
    ('http://192.168.10.168/',         'admin',             'admin',         'http://192.168.10.168/'),
    ('https://github.com/',            'j.smith2019',       'Gh1tHub@c0rp',  'https://github.com/'),
    ('https://jira.corp.local/',       'jsmith',            'Jira@2024!',    'https://jira.corp.local/'),
]

# ── Chrome / Chromium ─────────────────────────────────────────────────────────

def chrome_encrypt(password: str) -> bytes:
    """AES-128-CBC with key derived from 'peanuts', prefixed v10 (Linux default)."""
    kdf = PBKDF2HMAC(algorithm=hashes.SHA1(), length=16,
                     salt=b'saltysalt', iterations=1, backend=default_backend())
    key = kdf.derive(b'peanuts')
    padder = sym_padding.PKCS7(128).padder()
    padded = padder.update(password.encode()) + padder.finalize()
    enc = Cipher(algorithms.AES(key), modes.CBC(b' ' * 16),
                 backend=default_backend()).encryptor()
    return b'v10' + enc.update(padded) + enc.finalize()

def chrome_ts() -> int:
    return int((datetime.datetime.now().timestamp() + 11644473600) * 1_000_000)

def create_login_data(path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path):
        os.remove(path)
    conn = sqlite3.connect(path)
    c = conn.cursor()
    c.executescript('''
        CREATE TABLE logins (
            origin_url VARCHAR NOT NULL, action_url VARCHAR,
            username_element VARCHAR, username_value VARCHAR,
            password_element VARCHAR, password_value BLOB,
            submit_element VARCHAR, signon_realm VARCHAR NOT NULL,
            date_created INTEGER NOT NULL, blacklisted_by_user INTEGER NOT NULL,
            scheme INTEGER NOT NULL, password_type INTEGER NOT NULL DEFAULT 0,
            times_used INTEGER NOT NULL DEFAULT 0, form_data BLOB NOT NULL DEFAULT '',
            display_name VARCHAR NOT NULL DEFAULT '', icon_url VARCHAR NOT NULL DEFAULT '',
            federation_url VARCHAR NOT NULL DEFAULT '',
            skip_zero_click INTEGER NOT NULL DEFAULT 0,
            generation_upload_status INTEGER NOT NULL DEFAULT 0,
            possible_username_pairs BLOB NOT NULL DEFAULT '',
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date_last_used INTEGER NOT NULL DEFAULT 0,
            moving_blocked_for BLOB,
            date_password_modified INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE meta (key LONGVARCHAR NOT NULL UNIQUE PRIMARY KEY, value LONGVARCHAR);
        INSERT INTO meta VALUES ('version', '29');
        INSERT INTO meta VALUES ('last_compatible_version', '29');
    ''')
    ts = chrome_ts()
    for origin, username, password, realm in LOGINS:
        c.execute(
            '''INSERT INTO logins
               (origin_url, action_url, username_element, username_value,
                password_element, password_value, signon_realm,
                date_created, blacklisted_by_user, scheme, times_used, date_last_used)
               VALUES (?, ?, 'user', ?, 'pass', ?, ?, ?, 0, 0, 3, ?)''',
            (origin, origin, username, chrome_encrypt(password), realm, ts, ts))
    conn.commit()
    conn.close()
    print(f'[+] {path}')

create_login_data(os.path.join(JSMITH, '.config/google-chrome/Default/Login Data'))
create_login_data(os.path.join(JSMITH, '.config/chromium/Default/Login Data'))

# ── Firefox (NSS / PK11SDR) ───────────────────────────────────────────────────

PROFILE_NAME = 'k3b8m21s.default-release'
FF_PROFILE   = os.path.join(JSMITH, '.mozilla/firefox', PROFILE_NAME)

class SECItem(ctypes.Structure):
    _fields_ = [
        ('type', ctypes.c_uint),
        ('data', ctypes.c_void_p),
        ('len',  ctypes.c_uint),
    ]

lib_name = ctypes.util.find_library('nss3') or 'libnss3.so'
try:
    nss = ctypes.CDLL(lib_name)
except OSError:
    sys.exit('[!] libnss3 not found; install libnss3 and retry')

nss.NSS_InitReadWrite.restype           = ctypes.c_int
nss.NSS_InitReadWrite.argtypes          = [ctypes.c_char_p]
nss.NSS_Shutdown.restype                = ctypes.c_int
nss.PK11SDR_Encrypt.restype             = ctypes.c_int
nss.PK11SDR_Encrypt.argtypes            = [
    ctypes.POINTER(SECItem),   # keyID  (NULL → use default SDR key)
    ctypes.POINTER(SECItem),   # data
    ctypes.POINTER(SECItem),   # result
    ctypes.c_void_p,           # cx
]
nss.SECITEM_FreeItem.restype            = None
nss.SECITEM_FreeItem.argtypes           = [ctypes.POINTER(SECItem), ctypes.c_uint]
nss.PK11_GetInternalKeySlot.restype     = ctypes.c_void_p
nss.PK11_GetInternalKeySlot.argtypes    = []
nss.PK11_InitPin.restype                = ctypes.c_int
nss.PK11_InitPin.argtypes               = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]

# Remove stale NSS files so InitReadWrite starts clean
os.makedirs(FF_PROFILE, exist_ok=True)
for fname in ('key4.db', 'cert9.db', 'pkcs11.txt'):
    p = os.path.join(FF_PROFILE, fname)
    if os.path.exists(p):
        os.remove(p)

rv = nss.NSS_InitReadWrite(FF_PROFILE.encode())
if rv != 0:
    sys.exit(f'[!] NSS_InitReadWrite returned {rv}')

# Initialize the internal key slot with an empty master password
slot = nss.PK11_GetInternalKeySlot()
if slot:
    nss.PK11_InitPin(ctypes.c_void_p(slot), b'', b'')

def sdr_encrypt(value: str) -> str:
    raw = value.encode('utf-8')
    buf = ctypes.create_string_buffer(raw)
    src    = SECItem(0, ctypes.cast(buf, ctypes.c_void_p), len(raw))
    key_id = SECItem(0, None, 0)   # empty keyid → use default SDR key
    dst    = SECItem(0, None, 0)
    if nss.PK11SDR_Encrypt(ctypes.byref(key_id), ctypes.byref(src), ctypes.byref(dst), None) != 0:
        raise RuntimeError(f'PK11SDR_Encrypt failed for {value!r}')
    result = ctypes.string_at(dst.data, dst.len)
    nss.SECITEM_FreeItem(ctypes.byref(dst), 0)
    return base64.b64encode(result).decode()

def rand_guid() -> str:
    h = secrets.token_hex(16)
    return '{%s-%s-%s-%s-%s}' % (h[0:8], h[8:12], h[12:16], h[16:20], h[20:32])

logins_out = []
for i, (origin, username, password, _) in enumerate(LOGINS):
    logins_out.append({
        'id': i + 1,
        'hostname': origin.rstrip('/'),
        'httpRealm': None,
        'formSubmitURL': origin,
        'usernameField': 'username',
        'passwordField': 'password',
        'encryptedUsername': sdr_encrypt(username),
        'encryptedPassword': sdr_encrypt(password),
        'guid': rand_guid(),
        'encType': 1,
        'timeCreated':         1609459200000,
        'timeLastUsed':        1672531200000,
        'timePasswordChanged': 1609459200000,
        'timesUsed': 5,
    })

nss.NSS_Shutdown()

with open(os.path.join(FF_PROFILE, 'logins.json'), 'w') as f:
    json.dump({'nextId': len(logins_out) + 1, 'logins': logins_out}, f, indent=2)

with open(os.path.join(FF_PROFILE, 'prefs.js'), 'w') as f:
    f.write('user_pref("signon.rememberSignons", true);\n')

# profiles.ini so tools that walk ~/.mozilla/firefox find the profile
profiles_ini = os.path.join(JSMITH, '.mozilla/firefox/profiles.ini')
with open(profiles_ini, 'w') as f:
    f.write(f'[Profile0]\nName=default-release\nIsRelative=1\nPath={PROFILE_NAME}\nDefault=1\n\n'
            f'[General]\nStartWithLastProfile=1\nVersion=2\n')

print(f'[+] {FF_PROFILE}')
print('[+] Done.')
