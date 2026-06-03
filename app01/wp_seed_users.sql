-- Extra WordPress admin accounts that match shares/backups/wp_users_dump.sql.
-- WordPress accepts a legacy plain-MD5 in user_pass and upgrades it to phpash
-- on first successful login, so these MD5 hashes log in directly.
--
-- Apply AFTER you finish the WordPress install wizard (the wizard creates the
-- primary admin; these are additional admins). Run from the lab directory:
--   docker exec -i app01 mysql -uroot -proot wordpress < box3-app01/wp_seed_users.sql
--
-- Default table prefix wp_ assumed (matches the lab config).

-- jsmith / password123
INSERT INTO wp_users (user_login,user_pass,user_nicename,user_email,user_registered,display_name)
VALUES ('jsmith','482c811da5d5b4bc6d497ffa98491e38','jsmith','jsmith@corp.local',NOW(),'jsmith');
SET @uid := LAST_INSERT_ID();
INSERT INTO wp_usermeta (user_id,meta_key,meta_value) VALUES
  (@uid,'wp_capabilities','a:1:{s:13:"administrator";b:1;}'),
  (@uid,'wp_user_level','10');

-- agarcia / 123456
INSERT INTO wp_users (user_login,user_pass,user_nicename,user_email,user_registered,display_name)
VALUES ('agarcia','e10adc3949ba59abbe56e057f20f883e','agarcia','agarcia@corp.local',NOW(),'agarcia');
SET @uid := LAST_INSERT_ID();
INSERT INTO wp_usermeta (user_id,meta_key,meta_value) VALUES
  (@uid,'wp_capabilities','a:1:{s:13:"administrator";b:1;}'),
  (@uid,'wp_user_level','10');

-- backup / letmein
INSERT INTO wp_users (user_login,user_pass,user_nicename,user_email,user_registered,display_name)
VALUES ('backup','0d107d09f5bbe40cade3de5c71e9e9b7','backup','backup@corp.local',NOW(),'backup');
SET @uid := LAST_INSERT_ID();
INSERT INTO wp_usermeta (user_id,meta_key,meta_value) VALUES
  (@uid,'wp_capabilities','a:1:{s:13:"administrator";b:1;}'),
  (@uid,'wp_user_level','10');
