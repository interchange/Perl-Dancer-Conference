-- Convert schema 'sql/_source/deploy/24/001-auto.yml' to 'sql/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE conferences ALTER COLUMN uri SET NOT NULL;

;
ALTER TABLE conferences ALTER COLUMN logo SET NOT NULL;

;
ALTER TABLE conferences ALTER COLUMN email SET NOT NULL;

;

COMMIT;

