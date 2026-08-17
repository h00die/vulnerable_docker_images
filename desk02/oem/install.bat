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

rem --- anonymous (null-session) read-only share of C:\
rem 3 pieces must line up: share ACL for Everyone, the server-side
rem NullSessionShares list (anonymous may only touch listed shares), and
rem EveryoneIncludesAnonymous (null token joins Everyone). NTFS grant is
rem needed too - the null token is in none of C:'s default ACLs.
net share C=C:\ /grant:Everyone,READ /remark:"Public"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v NullSessionShares /t REG_MULTI_SZ /d "C" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v EveryoneIncludesAnonymous /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymous /t REG_DWORD /d 0 /f
rem --- bonus: let null sessions enumerate SAM users/lists (smb_enumusers)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymousSam /t REG_DWORD /d 0 /f
rem --- read+execute for Everyone down the tree (/t walks all of C:; /c skip
rem --- errors on TrustedInstaller-owned objects, /q keep it quiet)
icacls C:\ /grant Everyone:(OI)(CI)RX /t /c /q

rem --- Windows Update stays dead on purpose (Win7 EOL eval never patches,
rem --- which is the whole point - MS17-010 remains exploitable)

shutdown /r /t 10
