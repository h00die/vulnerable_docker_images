FROM wordpress:4.6-apache

COPY wp-cli.phar /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
