FROM wordpress:php7.2-fpm-alpine

# install wp-cli dependencies
RUN apk add --no-cache \
    less \
    mysql-client

# https://make.wordpress.org/cli/2018/05/31/gpg-signature-change/
# pub   rsa2048 2018-05-31 [SC]
#       63AF 7AA1 5067 C056 16FD  DD88 A3A2 E8F2 26F0 BC06
# uid           [ unknown] WP-CLI Releases <releases@wp-cli.org>
# sub   rsa2048 2018-05-31 [E]
ENV WORDPRESS_CLI_GPG_KEY 63AF7AA15067C05616FDDD88A3A2E8F226F0BC06

ENV WORDPRESS_CLI_VERSION 2.0.0
ENV WORDPRESS_CLI_SHA512 18c15c792a0747e434f70fb74f8d82dbc6dc504bd6238a4928859430129f12d88d829a1f37203c30813eb5f4d2c69f4e40aa15c74d9c6f01343052f01842463b

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
  command -v gpgconf && gpgconf --kill all || :; \
  rm -rf "$GNUPGHOME" /usr/local/bin/wp.gpg; \
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

RUN mkdir /run/nginx

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
