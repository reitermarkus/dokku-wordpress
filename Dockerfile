FROM wordpress:cli-php8.3 as cli

FROM wordpress:6.4.2-php8.3-fpm-alpine

# Install `wp-cli` and its dependencies.
COPY --from=cli /usr/local/bin/wp /usr/local/bin/wp
RUN apk add --no-cache \
    less~=643 \
    mysql-client~=10.11.5 \
 && wp --allow-root --version

RUN apk add --no-cache nginx~=1.24.0 \
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log \
 && echo 'cgi.fix_pathinfo=0' > /usr/local/etc/php/conf.d/cgi.ini
COPY wordpress.nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80

COPY php-fpm+nginx /usr/local/bin/php-fpm+nginx
RUN chmod +x /usr/local/bin/php-fpm+nginx \
 && sed -i "s|\[ \"\$1\" = 'php-fpm' \]|[ \"\$1\" = 'php-fpm+nginx' ]|" "$(which docker-entrypoint.sh)"
CMD ["php-fpm+nginx"]

RUN sed -i '/wpEnvs=/i \\        source /usr/local/bin/pre-entrypoint.sh'  "$(which docker-entrypoint.sh)"
COPY pre-entrypoint.sh /usr/local/bin/

RUN sed -i '/exec/i \\source /usr/local/bin/entrypoint.sh'  "$(which docker-entrypoint.sh)"
COPY entrypoint.sh /usr/local/bin/

# hadolint ignore=SC2016
RUN rm -r /usr/src/wordpress/wp-content/themes/twenty*   \
 && rm -r /usr/src/wordpress/wp-content/plugins/akismet        \
 && rm    /usr/src/wordpress/wp-content/plugins/hello.php \
 && sed -i 's/\[ "$(ls -A)" \]/false/' "$(which docker-entrypoint.sh)" \
 && sed -i 's/www-data:x:82:/www-data:x:1000:/' /etc/group \
 && sed -i 's/www-data:x:82:82:/www-data:x:1000:1000:/' /etc/passwd
