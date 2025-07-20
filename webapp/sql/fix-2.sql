USE isuconp;
ALTER TABLE `posts` ADD INDEX `idx_created_at_desc` (`created_at` DESC);
ALTER TABLE `posts` ADD INDEX `idx_created_at_asc` (`created_at` ASC);
