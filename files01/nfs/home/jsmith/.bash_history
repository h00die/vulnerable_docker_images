ssh jsmith@web01
sudo -l
mysql -h app01 -uroot -proot -e "show databases;"
redis-cli -h files01 ping
curl -u tomcat:tomcat http://app01:8080/manager/text/list
curl -u admin:admin123 http://app01:8080/manager/text/list
mount -t nfs files01:/data /mnt/share
ftp jsmith@web01
history -c
