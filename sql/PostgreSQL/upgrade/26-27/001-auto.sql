-- Convert schema 'sql/_source/deploy/26/001-auto.yml' to 'sql/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE talks ALTER COLUMN created SET NOT NULL;

;
ALTER TABLE talks ALTER COLUMN last_modified SET NOT NULL;

;

COMMIT;

