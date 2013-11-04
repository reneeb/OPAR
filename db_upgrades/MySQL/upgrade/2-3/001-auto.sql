-- Convert schema '/home/opar/OPAR/scripts/../db_upgrades/_source/deploy/2/001-auto.yml' to '/home/opar/OPAR/scripts/../db_upgrades/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `opr_notifications` (
  `notification_id` integer NOT NULL,
  `notification_type` VARCHAR(45) NULL,
  `notification_name` VARCHAR(45) NULL,
  `user_id` integer NOT NULL,
  INDEX `opr_notifications_idx_user_id` (`user_id`),
  PRIMARY KEY (`notification_id`),
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
DROP TABLE opr_feeds;

;
DROP TABLE opr_group;

;
DROP TABLE opr_group_user;

;

COMMIT;

