#!/bin/bash

wp() {
  su -s /bin/bash -m www-data -c -- 'wp "$@"' -- -- "$@"
}

if [[ -z "${WORDPRESS_HOME_URL:-}" ]] && [[ -z "${WORDPRESS_SITE_URL:-}" ]]; then
  echo 'At least one of WORDPRESS_HOME_URL or WORDPRESS_SITE_URL must be set.' >&2
  exit 1
fi

: ${WORDPRESS_HOME_URL:=${WORDPRESS_SITE_URL:-}}
: ${WORDPRESS_SITE_URL:=${WORDPRESS_HOME_URL:-}}

export WORDPRESS_HOME_URL
export WORDPRESS_SITE_URL

if ! wp core is-installed; then
  if [[ -z "${WORDPRESS_SITE_TITLE:-}" ]]; then
    echo 'WORDPRESS_SITE_TITLE must be set.' >&2
    exit 1
  fi

  wp core install --url="$WORDPRESS_SITE_URL" \
                  --title="$WORDPRESS_SITE_TITLE" \
                  --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
                  --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.org}"
fi

if [[ "$(wp option get siteurl)" != "$WORDPRESS_SITE_URL" ]]; then
  wp option update siteurl "$WORDPRESS_SITE_URL"
fi

if [[ ${WORDPRESS_OLD_HOME_URL:="$(wp option get home)"} != "$WORDPRESS_HOME_URL" ]]; then
  echo "Replacing '$WORDPRESS_OLD_HOME_URL' with '$WORDPRESS_HOME_URL'."
  wp option update home "$WORDPRESS_HOME_URL"
  wp search-replace "$WORDPRESS_OLD_HOME_URL" "$WORDPRESS_HOME_URL" --skip-columns=guid --precise
fi

if [[ -z "${WORDPRESS_THEME:-}" ]]; then
  echo 'WORDPRESS_THEME must be set.' >&2
  exit 1
fi

wp theme status "$WORDPRESS_THEME" | grep -q -wo Active ||
  wp theme activate "$WORDPRESS_THEME"

if [[ -n "${WORDPRESS_LANGUAGE:-}" ]]; then
  WORDPRESS_LANGUAGES="$WORDPRESS_LANGUAGE${WORDPRESS_LANGUAGES+",$WORDPRESS_LANGUAGES"}"
fi

IFS=',' languages=(${WORDPRESS_LANGUAGES:=})

if [[ -n "${WORDPRESS_LANGUAGES:-}" ]]; then
  export WORDPRESS_LANGUAGE="${languages[0]}"
  export WORDPRESS_LANGUAGES

  for language in ${languages[@]}; do
    {
      wp language core list --status=installed;
      wp language core list --status=active;
    } | grep -q -wo "$language" || wp language core install "$language"
  done
fi

if [[ -n "${WORDPRESS_LANGUAGE:-}" ]]; then
  wp site switch-language "$WORDPRESS_LANGUAGE"
fi

wp language core update
