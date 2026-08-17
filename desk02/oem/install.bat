@echo off
rem =====================================================================
rem  files01/windows OEM softener - dockur/windows copies this to C:\OEM
rem  and runs it as the LAST step of the unattended install, as SYSTEM.
rem  Everything here DELIBERATELY weakens the box for the lab.
rem =====================================================================

rem --- RDP on, NLA off: BlueKeep (CVE-2019-0708) reachable pre-auth by
rem --- auxiliary/scanner/rdp/cve_2019_0708_bluekeep
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f

rem --- weak local users for smb_login / ms17_010_psexec practice
net user lab_backdoor Passw0rd! /add /y
net localgroup administrators lab_backdoor /add
net user svc_backup backup123 /add /y

rem --- firewall fully off so scanners see clean protocol responses
netsh advfirewall set allprofiles state off

rem --- Windows Update stays dead on purpose (Win7 EOL eval never patches,
rem --- which is the whole point - MS17-010 remains exploitable)

shutdown /r /t 10
