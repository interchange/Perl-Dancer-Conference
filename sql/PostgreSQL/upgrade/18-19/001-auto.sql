-- Convert schema 'sql/_source/deploy/18/001-auto.yml' to 'sql/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "product_reviews" (
  "messages_id" integer NOT NULL,
  "sku" character varying(64) NOT NULL,
  PRIMARY KEY ("messages_id", "sku")
);
CREATE INDEX "product_reviews_idx_messages_id" on "product_reviews" ("messages_id");
CREATE INDEX "product_reviews_idx_sku" on "product_reviews" ("sku");

;
ALTER TABLE "product_reviews" ADD CONSTRAINT "product_reviews_fk_messages_id" FOREIGN KEY ("messages_id")
  REFERENCES "messages" ("messages_id") DEFERRABLE;

;
ALTER TABLE "product_reviews" ADD CONSTRAINT "product_reviews_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") DEFERRABLE;

;

COMMIT;

