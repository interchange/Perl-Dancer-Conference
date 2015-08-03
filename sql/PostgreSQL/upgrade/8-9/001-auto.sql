-- Convert schema 'sql/_source/deploy/8/001-auto.yml' to 'sql/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "events" (
  "events_id" serial NOT NULL,
  "conferences_id" integer NOT NULL,
  "duration" smallint NOT NULL,
  "title" character varying(255) NOT NULL,
  "abstract" character varying(2048) DEFAULT '' NOT NULL,
  "url" character varying(255) DEFAULT '' NOT NULL,
  "start_time" timestamp,
  "room" character varying(128) DEFAULT '' NOT NULL,
  PRIMARY KEY ("events_id")
);
CREATE INDEX "events_idx_conferences_id" on "events" ("conferences_id");

;
ALTER TABLE "events" ADD CONSTRAINT "events_fk_conferences_id" FOREIGN KEY ("conferences_id")
  REFERENCES "conferences" ("conferences_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

