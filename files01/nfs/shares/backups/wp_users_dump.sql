-- mysqldump of wp_users (legacy export, plain MD5 in user_pass)
INSERT INTO `wp_users` (`ID`,`user_login`,`user_pass`,`user_email`) VALUES
(7,'jsmith', '482c811da5d5b4bc6d497ffa98491e38','jsmith@corp.local'),
(8,'agarcia','e10adc3949ba59abbe56e057f20f883e','agarcia@corp.local'),
(9,'backup', '0d107d09f5bbe40cade3de5c71e9e9b7','backup@corp.local');
