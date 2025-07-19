USE isuconp;
ALTER TABLE `comments` ADD INDEX `comments_post_id_created_at` (`post_id`, `created_at`);
