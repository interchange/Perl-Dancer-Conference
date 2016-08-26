-- Convert schema 'sql/_source/deploy/28/001-auto.yml' to 'sql/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE talks ADD COLUMN organiser_notes character varying(2048) DEFAULT '' NOT NULL;

;

COMMIT;

