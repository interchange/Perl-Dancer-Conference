-- Convert schema 'sql/_source/deploy/13/001-auto.yml' to 'sql/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN guru_level integer DEFAULT 0 NOT NULL;

;

COMMIT;

