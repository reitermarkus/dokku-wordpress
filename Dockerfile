FROM wordpress:cli-php7.4 as cli

FROM wordpress:php7.4-fpm-alpine

# install wp-cli dependencies
RUN apk add --no-cache \
    less \
    mysql-client

COPY --from=cli /usr/local/bin/wp /usr/local/bin/wp

RUN wp --allow-root --version

RUN apk add --no-cache nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN echo 'cgi.fix_pathinfo=0' > /usr/local/etc/php/conf.d/cgi.ini

RUN mkdir /run/nginx
COPY wordpress.nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80

RUN sed -i -E "/^http \{$/i \\include modules/*.conf; \\" /etc/nginx/nginx.conf
RUN sed -i -E "/^http \{$/a \\    include conf.d/*.conf; \\" /etc/nginx/nginx.conf

COPY php-fpm+nginx /usr/local/bin/php-fpm+nginx
RUN chmod +x /usr/local/bin/php-fpm+nginx

RUN sed -i "s|\[ \"\$1\" = 'php-fpm' \]|[ \"\$1\" = 'php-fpm+nginx' ]|" "$(which docker-entrypoint.sh)"

CMD ["php-fpm+nginx"]

RUN sed -i '/wpEnvs=/i \\        source /usr/local/bin/pre-entrypoint.sh'  "$(which docker-entrypoint.sh)"
COPY pre-entrypoint.sh /usr/local/bin/

RUN sed -i "/# now that we're definitely done/i   \\  source /usr/local/bin/entrypoint.sh\\ \n" "$(which docker-entrypoint.sh)"
COPY entrypoint.sh /usr/local/bin/

RUN rm -r /usr/src/wordpress/wp-content/themes/twenty*   \
 && rm -r /usr/src/wordpress/wp-content/plugins/akismet        \
 && rm    /usr/src/wordpress/wp-content/plugins/hello.php \
 && sed -i 's/\[ "$(ls -A)" \]/false/' "$(which docker-entrypoint.sh)"

RUN sed -i 's/www-data:x:82:/www-data:x:1000:/' /etc/group
RUN sed -i 's/www-data:x:82:82:/www-data:x:1000:1000:/' /etc/passwd
