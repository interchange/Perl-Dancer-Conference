-- Convert schema 'sql/_source/deploy/23/001-auto.yml' to 'sql/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE conferences ADD COLUMN uri character varying(255);

;
ALTER TABLE conferences ADD COLUMN logo character varying(255);

;
ALTER TABLE conferences ADD COLUMN email character varying(255);

;

COMMIT;

