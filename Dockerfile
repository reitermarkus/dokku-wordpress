FROM wordpress:4-php7.1-apache

# pub   2048R/2F6B6B7F 2016-01-07
#       Key fingerprint = 3B91 9162 5F3B 1F1B F5DD  3B47 673A 0204 2F6B 6B7F
# uid   Daniel Bachhuber <daniel@handbuilt.co>
# sub   2048R/45F9CDE2 2016-01-07
ENV WORDPRESS_CLI_GPG_KEY 3B9191625F3B1F1BF5DD3B47673A02042F6B6B7F

ENV WORDPRESS_CLI_VERSION 1.5.0
ENV WORDPRESS_CLI_SHA512 9385c63ab835c7c450529035cdb1f524b5878a67c7565c3497628e5ec4ec07ae4a34ef25c59a9e7d6edea7cdb039fcef7a1f731b922782b8c70418480bdff122

RUN set -ex; \
  \
  apt-get update -q && \
  apt-get install -y -qq \
    gnupg \
    less \
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
  wp --allow-root --version

RUN sed -i '/haveConfig=$/i \\source /usr/local/bin/pre-entrypoint.sh'  "$(which docker-entrypoint.sh)"
COPY pre-entrypoint.sh /usr/local/bin/

RUN sed -i "/# now that we're definitely done/i   \\	source /usr/local/bin/entrypoint.sh\\ \n" "$(which docker-entrypoint.sh)"
COPY entrypoint.sh /usr/local/bin/

RUN rm -r /usr/src/wordpress/wp-content/themes/twentyfifteen   \
 && rm -r /usr/src/wordpress/wp-content/themes/twentysixteen   \
 && rm -r /usr/src/wordpress/wp-content/themes/twentyseventeen \
 && rm -r /usr/src/wordpress/wp-content/plugins/akismet        \
 && rm    /usr/src/wordpress/wp-content/plugins/hello.php \
 && sed -i 's/\[ "$(ls -A)" \]/false/' "$(which docker-entrypoint.sh)"
