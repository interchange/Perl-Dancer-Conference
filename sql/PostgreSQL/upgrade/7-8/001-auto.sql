-- Convert schema 'sql/_source/deploy/7/001-auto.yml' to 'sql/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE addresses ADD COLUMN latitude float(20);

;
ALTER TABLE addresses ADD COLUMN longitude float(30);

;

COMMIT;

