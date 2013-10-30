-- Convert schema '/home/opar/OPAR/scripts/../db_upgrades/_source/deploy/3/001-auto.yml' to '/home/opar/OPAR/scripts/../db_upgrades/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE opr_package ADD INDEX opr_package_idx_uploaded_by (uploaded_by),
                        ADD CONSTRAINT opr_package_fk_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES opr_user (user_id) ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

