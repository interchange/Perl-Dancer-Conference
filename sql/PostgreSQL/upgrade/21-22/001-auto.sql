-- Convert schema 'sql/_source/deploy/21/001-auto.yml' to 'sql/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "media_messages" (
  "media_id" integer NOT NULL,
  "messages_id" integer NOT NULL,
  PRIMARY KEY ("media_id", "messages_id")
);
CREATE INDEX "media_messages_idx_media_id" on "media_messages" ("media_id");
CREATE INDEX "media_messages_idx_messages_id" on "media_messages" ("messages_id");

;
ALTER TABLE "media_messages" ADD CONSTRAINT "media_messages_fk_media_id" FOREIGN KEY ("media_id")
  REFERENCES "medias" ("media_id") DEFERRABLE;

;
ALTER TABLE "media_messages" ADD CONSTRAINT "media_messages_fk_messages_id" FOREIGN KEY ("messages_id")
  REFERENCES "messages" ("messages_id") DEFERRABLE;

;

COMMIT;

