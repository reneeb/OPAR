-- Convert schema '/home/opar/OPAR/scripts/../db_upgrades/_source/deploy/4/001-auto.yml' to '/home/opar/OPAR/scripts/../db_upgrades/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE opr_notifications CHANGE COLUMN notification_id notification_id integer NOT NULL auto_increment;

;

COMMIT;

