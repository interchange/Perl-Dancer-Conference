-- Convert schema 'sql/_source/deploy/5/001-auto.yml' to 'sql/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE conference_tickets DROP CONSTRAINT conference_tickets_fk_sku;

;
ALTER TABLE conference_tickets ADD CONSTRAINT conference_tickets_fk_sku FOREIGN KEY (sku)
  REFERENCES products (sku) ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE messages ADD COLUMN summary character varying(1024) DEFAULT '' NOT NULL;

;
ALTER TABLE messages ADD COLUMN tags character varying(256) DEFAULT '' NOT NULL;

;

COMMIT;

