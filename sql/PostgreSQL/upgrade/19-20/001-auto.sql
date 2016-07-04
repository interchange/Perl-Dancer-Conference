-- Convert schema 'sql/_source/deploy/19/001-auto.yml' to 'sql/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE cart_products ADD COLUMN combine boolean DEFAULT 't' NOT NULL;

;
ALTER TABLE cart_products ADD COLUMN extra text;

;
ALTER TABLE products ADD COLUMN combine boolean DEFAULT 't' NOT NULL;

;

COMMIT;

