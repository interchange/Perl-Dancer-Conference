-- Convert schema 'sql/_source/deploy/11/001-auto.yml' to 'sql/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE events ADD COLUMN scheduled boolean DEFAULT '0' NOT NULL;

;

COMMIT;

