-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sun Nov  3 23:23:18 2013
-- 
;
SET foreign_key_checks=0;
--
-- Table: `opr_comments`
--
CREATE TABLE `opr_comments` (
  `comment_id` integer NOT NULL auto_increment,
  `username` VARCHAR(255) NOT NULL,
  `packagename` VARCHAR(255) NOT NULL,
  `packageversion` VARCHAR(255) NOT NULL,
  `comments` text NOT NULL,
  `rating` integer NULL DEFAULT NULL,
  `deletion_flag` BIGINT NULL DEFAULT NULL,
  `headline` VARCHAR(255) NULL DEFAULT NULL,
  `published` BIGINT NULL DEFAULT NULL,
  `created` BIGINT NULL DEFAULT NULL,
  PRIMARY KEY (`comment_id`)
);
--
-- Table: `opr_formid`
--
CREATE TABLE `opr_formid` (
  `formid` VARCHAR(255) NOT NULL,
  `used` TINYINT NULL DEFAULT NULL,
  `expire` BIGINT NULL DEFAULT NULL,
  PRIMARY KEY (`formid`)
);
--
-- Table: `opr_framework_versions`
--
CREATE TABLE `opr_framework_versions` (
  `framework` VARCHAR(8) NOT NULL,
  PRIMARY KEY (`framework`)
);
--
-- Table: `opr_job_type`
--
CREATE TABLE `opr_job_type` (
  `type_id` integer NOT NULL auto_increment,
  `type_label` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`type_id`)
) ENGINE=InnoDB;
--
-- Table: `opr_oq_entity`
--
CREATE TABLE `opr_oq_entity` (
  `oq_id` integer NOT NULL auto_increment,
  `oq_label` VARCHAR(255) NOT NULL,
  `priority` integer NOT NULL,
  `module` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`oq_id`)
) ENGINE=InnoDB;
--
-- Table: `opr_package_names`
--
CREATE TABLE `opr_package_names` (
  `name_id` integer NOT NULL auto_increment,
  `package_name` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`name_id`)
) ENGINE=InnoDB;
--
-- Table: `opr_repo`
--
CREATE TABLE `opr_repo` (
  `repo_id` VARCHAR(100) NOT NULL,
  `framework` VARCHAR(8) NULL DEFAULT NULL,
  `email` VARCHAR(255) NULL DEFAULT NULL,
  `index_file` text NULL DEFAULT NULL,
  PRIMARY KEY (`repo_id`)
) ENGINE=InnoDB;
--
-- Table: `opr_tags`
--
CREATE TABLE `opr_tags` (
  `tag_id` integer NOT NULL auto_increment,
  `tag_name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`tag_id`)
) ENGINE=InnoDB;
--
-- Table: `opr_user`
--
CREATE TABLE `opr_user` (
  `user_id` integer NOT NULL auto_increment,
  `user_name` VARCHAR(255) NOT NULL,
  `user_password` VARCHAR(255) NOT NULL,
  `session_id` VARCHAR(255) NULL DEFAULT NULL,
  `website` VARCHAR(255) NULL DEFAULT NULL,
  `mail` VARCHAR(255) NOT NULL,
  `active` TINYINT NULL DEFAULT NULL,
  `registered` integer NULL DEFAULT NULL,
  `realname` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB;
--
-- Table: `opr_notifications`
--
CREATE TABLE `opr_notifications` (
  `notification_id` integer NOT NULL auto_increment,
  `notification_type` VARCHAR(45) NULL,
  `notification_name` VARCHAR(45) NULL,
  `user_id` integer NOT NULL,
  INDEX `opr_notifications_idx_user_id` (`user_id`),
  PRIMARY KEY (`notification_id`),
  CONSTRAINT `opr_notifications_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `opr_user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `opr_temp_passwd`
--
CREATE TABLE `opr_temp_passwd` (
  `id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `token` VARCHAR(255) NULL DEFAULT NULL,
  `created` integer NULL DEFAULT NULL,
  INDEX `opr_temp_passwd_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `opr_temp_passwd_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `opr_user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `opr_package`
--
CREATE TABLE `opr_package` (
  `package_id` integer NOT NULL auto_increment,
  `name_id` integer NOT NULL,
  `uploaded_by` integer NOT NULL,
  `description` text NULL DEFAULT NULL,
  `version` VARCHAR(255) NULL DEFAULT NULL,
  `framework` VARCHAR(255) NULL DEFAULT NULL,
  `path` VARCHAR(255) NOT NULL,
  `is_in_index` TINYINT NULL DEFAULT NULL,
  `website` VARCHAR(255) NULL DEFAULT NULL,
  `bugtracker` VARCHAR(255) NULL DEFAULT NULL,
  `upload_time` integer NULL DEFAULT NULL,
  `virtual_path` VARCHAR(255) NULL DEFAULT NULL,
  `deletion_flag` BIGINT NULL DEFAULT NULL,
  `documentation` text NULL DEFAULT NULL,
  `downloads` integer NOT NULL DEFAULT ''0'',
  `documentation_raw` text NULL DEFAULT NULL,
  INDEX `opr_package_idx_name_id` (`name_id`),
  INDEX `opr_package_idx_uploaded_by` (`uploaded_by`),
  PRIMARY KEY (`package_id`),
  CONSTRAINT `opr_package_fk_name_id` FOREIGN KEY (`name_id`) REFERENCES `opr_package_names` (`name_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `opr_package_fk_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `opr_user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `opr_package_author`
--
CREATE TABLE `opr_package_author` (
  `user_id` integer NOT NULL,
  `name_id` integer NOT NULL,
  `is_main_author` TINYINT NOT NULL,
  INDEX `opr_package_author_idx_name_id` (`name_id`),
  INDEX (`user_id`),
  PRIMARY KEY (`user_id`),
  CONSTRAINT `opr_package_author_fk_name_id` FOREIGN KEY (`name_id`) REFERENCES `opr_package_names` (`name_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `opr_package_author_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `opr_user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `opr_package_tags`
--
CREATE TABLE `opr_package_tags` (
  `name_id` integer NOT NULL,
  `tag_id` integer NOT NULL,
  INDEX `opr_package_tags_idx_name_id` (`name_id`),
  INDEX `opr_package_tags_idx_tag_id` (`tag_id`),
  PRIMARY KEY (`name_id`, `tag_id`),
  CONSTRAINT `opr_package_tags_fk_name_id` FOREIGN KEY (`name_id`) REFERENCES `opr_package_names` (`name_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `opr_package_tags_fk_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `opr_tags` (`tag_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `opr_repo_package`
--
CREATE TABLE `opr_repo_package` (
  `name_id` integer NOT NULL,
  `repo_id` VARCHAR(100) NOT NULL,
  INDEX `opr_repo_package_idx_name_id` (`name_id`),
  INDEX `opr_repo_package_idx_repo_id` (`repo_id`),
  PRIMARY KEY (`name_id`, `repo_id`),
  CONSTRAINT `opr_repo_package_fk_name_id` FOREIGN KEY (`name_id`) REFERENCES `opr_package_names` (`name_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `opr_repo_package_fk_repo_id` FOREIGN KEY (`repo_id`) REFERENCES `opr_repo` (`repo_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `opr_package_dependencies`
--
CREATE TABLE `opr_package_dependencies` (
  `dependency_id` integer NOT NULL auto_increment,
  `package_id` integer NOT NULL,
  `dependency` VARCHAR(255) NOT NULL,
  `dependency_type` ENUM() NOT NULL,
  `dependency_version` VARCHAR(255) NULL DEFAULT NULL,
  INDEX `opr_package_dependencies_idx_package_id` (`package_id`),
  PRIMARY KEY (`dependency_id`),
  CONSTRAINT `opr_package_dependencies_fk_package_id` FOREIGN KEY (`package_id`) REFERENCES `opr_package` (`package_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `opr_job_queue`
--
CREATE TABLE `opr_job_queue` (
  `job_id` integer NOT NULL auto_increment,
  `type_id` integer NOT NULL,
  `package_id` integer NOT NULL,
  `created` BIGINT NULL DEFAULT NULL,
  `job_state` VARCHAR(255) NULL DEFAULT NULL,
  `changed` BIGINT NULL DEFAULT NULL,
  INDEX `opr_job_queue_idx_type_id` (`type_id`),
  INDEX `opr_job_queue_idx_package_id` (`package_id`),
  PRIMARY KEY (`job_id`),
  CONSTRAINT `opr_job_queue_fk_type_id` FOREIGN KEY (`type_id`) REFERENCES `opr_job_type` (`type_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `opr_job_queue_fk_package_id` FOREIGN KEY (`package_id`) REFERENCES `opr_package` (`package_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `opr_oq_result`
--
CREATE TABLE `opr_oq_result` (
  `result_id` integer NOT NULL auto_increment,
  `oq_id` integer NOT NULL,
  `package_id` integer NOT NULL,
  `oq_result` text NULL DEFAULT NULL,
  `filename` VARCHAR(255) NULL DEFAULT NULL,
  INDEX `opr_oq_result_idx_oq_id` (`oq_id`),
  INDEX `opr_oq_result_idx_package_id` (`package_id`),
  PRIMARY KEY (`result_id`),
  CONSTRAINT `opr_oq_result_fk_oq_id` FOREIGN KEY (`oq_id`) REFERENCES `opr_oq_entity` (`oq_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `opr_oq_result_fk_package_id` FOREIGN KEY (`package_id`) REFERENCES `opr_package` (`package_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
SET foreign_key_checks=1;
