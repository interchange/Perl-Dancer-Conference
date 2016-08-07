-- Convert schema 'sql/_source/deploy/25/001-auto.yml' to 'sql/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE talks ADD COLUMN created timestamp;

;
ALTER TABLE talks ADD COLUMN last_modified timestamp;

;

COMMIT;

