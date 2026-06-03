<?php
/** WordPress config (copied here for the migration - jsmith) */
define('DB_NAME',     'wordpress');
define('DB_USER',     'wordpress');
define('DB_PASSWORD', 'wordpress');
define('DB_HOST',     'app01:3306');
$table_prefix = 'wp_';

// TODO: move these out of the NFS share before go-live (OPS-1477)
define('AUTH_KEY',        'p7$Lab-not-a-real-secret-9f8a2c');
define('SECURE_AUTH_KEY', 'q2#Lab-not-a-real-secret-1d4e6b');
define('LOGGED_IN_KEY',   'z9!Lab-not-a-real-secret-7a3f1e');

if ( ! defined('ABSPATH') ) define('ABSPATH', __DIR__ . '/');
require_once ABSPATH . 'wp-settings.php';
