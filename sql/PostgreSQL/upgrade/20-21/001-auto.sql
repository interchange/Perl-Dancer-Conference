-- Convert schema 'sql/_source/deploy/20/001-auto.yml' to 'sql/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "navigation_messages" (
  "messages_id" integer NOT NULL,
  "navigation_id" integer NOT NULL,
  PRIMARY KEY ("messages_id", "navigation_id")
);
CREATE INDEX "navigation_messages_idx_messages_id" on "navigation_messages" ("messages_id");
CREATE INDEX "navigation_messages_idx_navigation_id" on "navigation_messages" ("navigation_id");

;
ALTER TABLE "navigation_messages" ADD CONSTRAINT "navigation_messages_fk_messages_id" FOREIGN KEY ("messages_id")
  REFERENCES "messages" ("messages_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "navigation_messages" ADD CONSTRAINT "navigation_messages_fk_navigation_id" FOREIGN KEY ("navigation_id")
  REFERENCES "navigations" ("navigation_id") ON DELETE CASCADE DEFERRABLE;

;

COMMIT;

