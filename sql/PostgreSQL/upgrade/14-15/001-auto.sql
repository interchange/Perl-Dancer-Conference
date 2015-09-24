-- Convert schema 'sql/_source/deploy/14/001-auto.yml' to 'sql/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN t_shirt_size character varying(8);

;

COMMIT;

