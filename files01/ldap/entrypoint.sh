#!/bin/bash
# Wait for slapd, then open up anonymous read access via cn=config (requires SASL EXTERNAL)
(
  until ldapsearch -x -H ldap://127.0.0.1 -b "" -s base namingContexts >/dev/null 2>&1; do
    sleep 1
  done

  cat > /tmp/fix_acl.ldif << 'LDIF'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break
olcAccess: to attrs=userPassword,shadowLastChange by self write by dn="cn=admin,dc=corp,dc=local" write by anonymous auth by * none
olcAccess: to * by self read by dn="cn=admin,dc=corp,dc=local" write by dn="cn=ldapro,dc=corp,dc=local" read by anonymous read by * none
LDIF

  ldapmodify -Y EXTERNAL -H ldapi://%2Frun%2Fslapd%2Fldapi -f /tmp/fix_acl.ldif
  echo "[ldap-entrypoint] ACL fix exit code: $?"
) &

exec /container/tool/run "$@"
