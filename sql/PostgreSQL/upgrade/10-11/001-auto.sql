-- Convert schema 'sql/_source/deploy/10/001-auto.yml' to 'sql/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE conferences ADD COLUMN end_date date;

;
ALTER TABLE talks ADD COLUMN scheduled boolean DEFAULT '0' NOT NULL;

;

COMMIT;

