FROM wordpress:php7.1-fpm-alpine

# install wp-cli dependencies
RUN apk add --no-cache \
    less \
    mysql-client

# pub   2048R/2F6B6B7F 2016-01-07
#       Key fingerprint = 3B91 9162 5F3B 1F1B F5DD  3B47 673A 0204 2F6B 6B7F
# uid   Daniel Bachhuber <daniel@handbuilt.co>
# sub   2048R/45F9CDE2 2016-01-07
ENV WORDPRESS_CLI_GPG_KEY 3B9191625F3B1F1BF5DD3B47673A02042F6B6B7F

ENV WORDPRESS_CLI_VERSION 1.3.0
ENV WORDPRESS_CLI_SHA512 710d41171358fbaff5962e23d1acfda1327e03cbc59bb7c5d8a7ff87fee009ac678bc8f8e690bc743f40bc54ae8907f1f16e4e5abd166c05dc7769cd15b00084

RUN set -ex; \
  \
  apk add --no-cache --virtual .fetch-deps \
    gnupg \
  ; \
  \
  curl -o /usr/local/bin/wp.gpg -fSL "https://github.com/wp-cli/wp-cli/releases/download/v${WORDPRESS_CLI_VERSION}/wp-cli-${WORDPRESS_CLI_VERSION}.phar.gpg"; \
  \
  export GNUPGHOME="$(mktemp -d)"; \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$WORDPRESS_CLI_GPG_KEY"; \
  gpg --batch --decrypt --output /usr/local/bin/wp /usr/local/bin/wp.gpg; \
  rm -r "$GNUPGHOME" /usr/local/bin/wp.gpg; \
  \
  echo "$WORDPRESS_CLI_SHA512 */usr/local/bin/wp" | sha512sum -c -; \
  chmod +x /usr/local/bin/wp; \
  \
  apk del .fetch-deps; \
  \
  wp --allow-root --version


RUN apk add --no-cache nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN echo 'cgi.fix_pathinfo=0' > /usr/local/etc/php/conf.d/cgi.ini

RUN mkdir /etc/nginx/modules
RUN echo 'daemon off;' > /etc/nginx/modules/daemon.conf
RUN echo 'pid /var/run/nginx.pid;' > /etc/nginx/modules/pid.conf

COPY wordpress.nginx.conf /etc/nginx/conf.d/default.conf

RUN sed -i -E "/^http \{$/i \\include modules/*.conf; \\" /etc/nginx/nginx.conf
RUN sed -i -E "/^http \{$/a \\    include conf.d/*.conf; \\" /etc/nginx/nginx.conf

COPY php-fpm+nginx /usr/local/bin/php-fpm+nginx
RUN chmod +x /usr/local/bin/php-fpm+nginx

RUN sed -i 's|\[ "$1" == php-fpm \]|[ "$1" == php-fpm+nginx ]|' "$(which docker-entrypoint.sh)"

CMD ["php-fpm+nginx"]

RUN sed -i '/haveConfig=$/i \\source /usr/local/bin/pre-entrypoint.sh'  "$(which docker-entrypoint.sh)"
COPY pre-entrypoint.sh /usr/local/bin/

RUN sed -i "/# now that we're definitely done/i   \\  source /usr/local/bin/entrypoint.sh\\ \n" "$(which docker-entrypoint.sh)"
COPY entrypoint.sh /usr/local/bin/

RUN rm -r /usr/src/wordpress/wp-content/themes/twentyfifteen   \
 && rm -r /usr/src/wordpress/wp-content/themes/twentysixteen   \
 && rm -r /usr/src/wordpress/wp-content/themes/twentyseventeen \
 && rm -r /usr/src/wordpress/wp-content/plugins/akismet        \
 && rm    /usr/src/wordpress/wp-content/plugins/hello.php \
 && sed -i 's/\[ "$(ls -A)" \]/false/' "$(which docker-entrypoint.sh)"
