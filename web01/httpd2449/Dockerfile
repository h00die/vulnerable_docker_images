# Apache httpd 2.4.49 — CVE-2021-41773 path traversal (→ RCE with CGI on).
# The official 2.4.49 image IS the vulnerable version; the only change is
# enabling mod_cgid (off by default) so the traversal reaches RCE, and
# moving to :8081 because DVWA owns :80 on this box.
FROM httpd:2.4.49
RUN sed -i 's/^Listen 80$/Listen 8081/' /usr/local/apache2/conf/httpd.conf \
 && sed -i 's/^[[:space:]]*#LoadModule cgid_module/LoadModule cgid_module/' /usr/local/apache2/conf/httpd.conf \
 && sed -i '0,/Require all denied/s//Require all granted/' /usr/local/apache2/conf/httpd.conf
# ^ the stock config denies the filesystem root, which blocks the traversal;
#   per the advisory the bug bites when outside-docroot files are NOT denied
