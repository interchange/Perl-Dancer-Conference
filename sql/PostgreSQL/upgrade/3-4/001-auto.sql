-- Convert schema 'sql/_source/deploy/3/001-auto.yml' to 'sql/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "conference_tickets" (
  "conferences_id" integer NOT NULL,
  "sku" character varying(64) NOT NULL,
  PRIMARY KEY ("conferences_id", "sku")
);
CREATE INDEX "conference_tickets_idx_conferences_id" on "conference_tickets" ("conferences_id");
CREATE INDEX "conference_tickets_idx_sku" on "conference_tickets" ("sku");

;
ALTER TABLE "conference_tickets" ADD CONSTRAINT "conference_tickets_fk_conferences_id" FOREIGN KEY ("conferences_id")
  REFERENCES "conferences" ("conferences_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "conference_tickets" ADD CONSTRAINT "conference_tickets_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") DEFERRABLE;

;

COMMIT;

