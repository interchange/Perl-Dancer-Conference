-- Convert schema 'sql/_source/deploy/4/001-auto.yml' to 'sql/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE talks ALTER COLUMN author_id DROP NOT NULL;

;

COMMIT;

