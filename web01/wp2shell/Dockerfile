# Sourced from https://github.com/M4xSec/wp2shell-lab (lab/Dockerfile, no-WAF variant)
FROM wordpress:6.9.0-php8.3-apache

# Install WP-CLI for automated setup
RUN curl -sL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp && chmod +x /usr/local/bin/wp

# Setup script: auto-install WordPress + create a published post (oEmbed anchor)
COPY setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

ENTRYPOINT ["setup.sh"]
CMD ["apache2-foreground"]
