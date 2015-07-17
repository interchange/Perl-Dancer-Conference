-- Convert schema 'sql/_source/deploy/2/001-auto.yml' to 'sql/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN monger_groups character varying(256) DEFAULT '' NOT NULL;

;

COMMIT;

