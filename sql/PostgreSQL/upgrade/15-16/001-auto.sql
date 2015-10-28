-- Convert schema 'sql/_source/deploy/15/001-auto.yml' to 'sql/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "survey_question_options" (
  "survey_question_option_id" serial NOT NULL,
  "title" character varying(255) NOT NULL,
  "priority" integer NOT NULL,
  "survey_question_id" integer NOT NULL,
  PRIMARY KEY ("survey_question_option_id")
);
CREATE INDEX "survey_question_options_idx_survey_question_id" on "survey_question_options" ("survey_question_id");

;
CREATE TABLE "survey_questions" (
  "survey_question_id" serial NOT NULL,
  "title" character varying(255) NOT NULL,
  "description" character varying(2048) DEFAULT '' NOT NULL,
  "other" character varying(255) DEFAULT '' NOT NULL,
  "type" character varying(16) NOT NULL,
  "priority" integer NOT NULL,
  "survey_section_id" integer NOT NULL,
  PRIMARY KEY ("survey_question_id")
);
CREATE INDEX "survey_questions_idx_survey_section_id" on "survey_questions" ("survey_section_id");

;
CREATE TABLE "survey_sections" (
  "survey_section_id" serial NOT NULL,
  "title" character varying(255) NOT NULL,
  "description" character varying(2048) DEFAULT '' NOT NULL,
  "priority" integer NOT NULL,
  "survey_id" integer NOT NULL,
  PRIMARY KEY ("survey_section_id")
);
CREATE INDEX "survey_sections_idx_survey_id" on "survey_sections" ("survey_id");

;
CREATE TABLE "surveys" (
  "survey_id" serial NOT NULL,
  "title" character varying(255) NOT NULL,
  "conferences_id" integer NOT NULL,
  "author_id" integer NOT NULL,
  "public" boolean DEFAULT '0' NOT NULL,
  "closed" boolean DEFAULT '0' NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("survey_id"),
  CONSTRAINT "surveys_conferences_id_title" UNIQUE ("conferences_id", "title")
);
CREATE INDEX "surveys_idx_author_id" on "surveys" ("author_id");
CREATE INDEX "surveys_idx_conferences_id" on "surveys" ("conferences_id");

;
ALTER TABLE "survey_question_options" ADD CONSTRAINT "survey_question_options_fk_survey_question_id" FOREIGN KEY ("survey_question_id")
  REFERENCES "survey_questions" ("survey_question_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "survey_questions" ADD CONSTRAINT "survey_questions_fk_survey_section_id" FOREIGN KEY ("survey_section_id")
  REFERENCES "survey_sections" ("survey_section_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "survey_sections" ADD CONSTRAINT "survey_sections_fk_survey_id" FOREIGN KEY ("survey_id")
  REFERENCES "surveys" ("survey_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "surveys" ADD CONSTRAINT "surveys_fk_author_id" FOREIGN KEY ("author_id")
  REFERENCES "users" ("users_id") DEFERRABLE;

;
ALTER TABLE "surveys" ADD CONSTRAINT "surveys_fk_conferences_id" FOREIGN KEY ("conferences_id")
  REFERENCES "conferences" ("conferences_id") DEFERRABLE;

;

COMMIT;

