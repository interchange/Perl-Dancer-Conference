-- Convert schema 'sql/_source/deploy/16/001-auto.yml' to 'sql/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE survey_responses ADD COLUMN value integer;

;
ALTER TABLE user_surveys DROP CONSTRAINT user_surveys_fk_survey_id;

;
ALTER TABLE user_surveys ADD CONSTRAINT user_surveys_fk_survey_id FOREIGN KEY (survey_id)
  REFERENCES surveys (survey_id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

