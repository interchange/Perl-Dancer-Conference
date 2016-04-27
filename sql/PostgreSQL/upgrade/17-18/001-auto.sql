-- Convert schema 'sql/_source/deploy/17/001-auto.yml' to 'sql/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "media_navigations" (
  "media_id" integer NOT NULL,
  "navigation_id" integer NOT NULL,
  PRIMARY KEY ("media_id", "navigation_id")
);
CREATE INDEX "media_navigations_idx_media_id" on "media_navigations" ("media_id");
CREATE INDEX "media_navigations_idx_navigation_id" on "media_navigations" ("navigation_id");

;
CREATE TABLE "product_messages" (
  "messages_id" integer NOT NULL,
  "sku" character varying(64) NOT NULL,
  PRIMARY KEY ("messages_id", "sku")
);
CREATE INDEX "product_messages_idx_messages_id" on "product_messages" ("messages_id");
CREATE INDEX "product_messages_idx_sku" on "product_messages" ("sku");

;
ALTER TABLE "media_navigations" ADD CONSTRAINT "media_navigations_fk_media_id" FOREIGN KEY ("media_id")
  REFERENCES "medias" ("media_id") DEFERRABLE;

;
ALTER TABLE "media_navigations" ADD CONSTRAINT "media_navigations_fk_navigation_id" FOREIGN KEY ("navigation_id")
  REFERENCES "navigations" ("navigation_id") DEFERRABLE;

;
ALTER TABLE "product_messages" ADD CONSTRAINT "product_messages_fk_messages_id" FOREIGN KEY ("messages_id")
  REFERENCES "messages" ("messages_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "product_messages" ADD CONSTRAINT "product_messages_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE carts DROP CONSTRAINT carts_fk_sessions_id;

;
ALTER TABLE carts ADD CONSTRAINT carts_fk_sessions_id FOREIGN KEY (sessions_id)
  REFERENCES sessions (sessions_id) ON DELETE SET NULL DEFERRABLE;

;
ALTER TABLE medias ADD COLUMN priority integer DEFAULT 0 NOT NULL;

;
ALTER TABLE medias ALTER COLUMN file DROP NOT NULL;

;
ALTER TABLE medias ALTER COLUMN file DROP DEFAULT;

;
ALTER TABLE orderlines ALTER COLUMN price TYPE numeric(21,3);

;
ALTER TABLE orderlines ALTER COLUMN subtotal TYPE numeric(21,3);

;
ALTER TABLE orderlines ALTER COLUMN shipping TYPE numeric(21,3);

;
ALTER TABLE orderlines ALTER COLUMN shipping SET DEFAULT 0;

;
ALTER TABLE orderlines ALTER COLUMN handling TYPE numeric(21,3);

;
ALTER TABLE orderlines ALTER COLUMN handling SET DEFAULT 0;

;
ALTER TABLE orderlines ALTER COLUMN salestax TYPE numeric(21,3);

;
ALTER TABLE orderlines ALTER COLUMN salestax SET DEFAULT 0;

;
ALTER TABLE orderlines_shippings DROP CONSTRAINT orderlines_shippings_pkey;

;
ALTER TABLE orderlines_shippings ADD COLUMN quantity integer NOT NULL;

;
ALTER TABLE orderlines_shippings ADD PRIMARY KEY (orderlines_id, addresses_id, shipments_id);

;
ALTER TABLE orders ALTER COLUMN subtotal TYPE numeric(21,3);

;
ALTER TABLE orders ALTER COLUMN subtotal SET DEFAULT 0;

;
ALTER TABLE orders ALTER COLUMN shipping TYPE numeric(21,3);

;
ALTER TABLE orders ALTER COLUMN shipping SET DEFAULT 0;

;
ALTER TABLE orders ALTER COLUMN handling TYPE numeric(21,3);

;
ALTER TABLE orders ALTER COLUMN handling SET DEFAULT 0;

;
ALTER TABLE orders ALTER COLUMN salestax TYPE numeric(21,3);

;
ALTER TABLE orders ALTER COLUMN salestax SET DEFAULT 0;

;
ALTER TABLE orders ALTER COLUMN total_cost TYPE numeric(21,3);

;
ALTER TABLE orders ALTER COLUMN total_cost SET DEFAULT 0;

;
ALTER TABLE payment_orders ALTER COLUMN amount TYPE numeric(21,3);

;
ALTER TABLE payment_orders ALTER COLUMN amount SET DEFAULT 0;

;
ALTER TABLE payment_orders ALTER COLUMN payment_fee TYPE numeric(12,3);

;
ALTER TABLE payment_orders ALTER COLUMN payment_fee SET DEFAULT 0;

;
ALTER TABLE price_modifiers DROP CONSTRAINT price_modifiers_fk_sku;

;
ALTER TABLE price_modifiers ALTER COLUMN price TYPE numeric(21,3);

;
ALTER TABLE price_modifiers ADD CONSTRAINT price_modifiers_fk_sku FOREIGN KEY (sku)
  REFERENCES products (sku) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE products ALTER COLUMN price TYPE numeric(21,3);

;
ALTER TABLE products ALTER COLUMN price SET DEFAULT 0;

;
ALTER TABLE shipment_rates ALTER COLUMN price TYPE numeric(21,3);

;
ALTER TABLE shipment_rates ALTER COLUMN price SET DEFAULT 0;

;
ALTER TABLE users ALTER COLUMN password TYPE character varying(2048);

;
ALTER TABLE users ALTER COLUMN password SET DEFAULT '*';

;
DROP TABLE product_reviews CASCADE;

;

COMMIT;

