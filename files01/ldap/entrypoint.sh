#!/bin/bash
# Wait for slapd, then open up anonymous read access via cn=config (requires SASL EXTERNAL)
(
  until ldapsearch -x -H ldap://localhost -b "" -s base namingContexts >/dev/null 2>&1; do
    sleep 1
  done

  ldapmodify -Y EXTERNAL -H ldapi:/// 2>/dev/null << 'EOF'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break
olcAccess: {1}to attrs=userPassword,shadowLastChange by self write by dn="cn=admin,dc=corp,dc=local" write by anonymous auth by * none
olcAccess: {2}to * by self write by dn="cn=admin,dc=corp,dc=local" write by users read by anonymous read by * none
EOF
) &

exec /container/tool/run "$@"
