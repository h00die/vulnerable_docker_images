#!/usr/bin/env python3
"""IPMI 2.0 BMC simulator.

Vulnerable to:
  CVE-2013-4786 — RAKP authentication leaks HMAC-SHA1 hash of any username's
                  password to unauthenticated requesters (inherent IPMI 2.0 flaw).
  CVE-2013-4782 — Cipher suite 0 (no auth) accepted, allowing authentication
                  bypass with any password.

MSF modules:
  auxiliary/scanner/ipmi/ipmi_version
  auxiliary/scanner/ipmi/ipmi_dumphashes
  auxiliary/scanner/ipmi/ipmi_cipher_zero
"""

from pyghmi.ipmi import bmc


class LabBMC(bmc.Bmc):
    def get_boot_device(self):
        return {'bootdevice': 'default'}

    def get_system_boot_options(self, request, session):
        return

    def get_power_state(self):
        return 'on'

    def power_off(self):
        pass

    def power_on(self):
        pass

    def power_reset(self):
        pass

    def power_cycle(self):
        pass

    def cold_reset(self):
        pass


# Common default IPMI credentials found on real hardware.
# jsmith/password123 mirrors the credential reused across other lab services.
authdata = {
    'admin':  'admin',
    'Admin':  'admin',
    'ADMIN':  'ADMIN',
    'root':   'root',
    'jsmith': 'password123',
}

mybmc = LabBMC(authdata, port=623)
print('[ipmi] BMC listening on UDP 623', flush=True)
mybmc.listen()
