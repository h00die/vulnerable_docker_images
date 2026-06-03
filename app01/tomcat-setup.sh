#!/bin/bash
# Make Tomcat's Manager app reachable remotely. Keeps the classic default
# tomcat/tomcat, and adds admin/admin123 (matches the cracked .htpasswd on
# the NFS share). Works on tomcat:9.0 where webapps live in webapps.dist.
set -e

cp -rn /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps/ 2>/dev/null || true

cat > /usr/local/tomcat/conf/tomcat-users.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users>
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <role rolename="manager-jmx"/>
  <role rolename="manager-status"/>
  <role rolename="admin-gui"/>
  <role rolename="admin-script"/>
  <user username="tomcat" password="tomcat"
        roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>
  <user username="admin" password="admin123"
        roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>
</tomcat-users>
EOF

cat > /usr/local/tomcat/webapps/manager/META-INF/context.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" />
EOF
cat > /usr/local/tomcat/webapps/host-manager/META-INF/context.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" />
EOF

exec catalina.sh run
