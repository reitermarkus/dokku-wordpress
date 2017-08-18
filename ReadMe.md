# WordPress with Dokku Support

This image includes WP-CLI and removes all default plugins and themes.

## Environment Variables

Since this image is derived from the official WordPress image, all variables from it are supported.

Additionally, these are available:

- `WORDPRESS_THEME`: name of the theme which should be activated on startup (must be set)
- `WORDPRESS_HOME_URL`: will set the `home` option in the database on startup,
                        if previous URL in the linked database differs, a search-and-replace will be done via WP-CLI. (must be set if `WORDPRESS_SITE_URL` is unset)
- `WORDPRESS_SITE_URL`: will set the `siteurl` option in the database on startup (must be set if `WORDPRESS_HOME_URL` is unset)
- `WORDPRESS_SITE_TITLE`: site title which will be set when not using an existing database
- `DATABASE_URL`: if set by Dokku, will be automatically split into
    - `WORDPRESS_DB_USER`,
    - `WORDPRESS_DB_PASSWORD`,
    - `WORDPRESS_DB_HOST` and
    - `WORDPRESS_DB_NAME`.
- `WORDPRESS_LANGUAGE`: language which will be set on startup
- `WORDPRESS_LANGUAGES`: comma-separated list of languages to download, `WORDPRESS_LANGUAGE` be set to the first one
