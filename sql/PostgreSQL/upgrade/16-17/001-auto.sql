-- Convert schema 'sql/_source/deploy/16/001-auto.yml' to 'sql/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE talks ADD COLUMN video_url character varying(255) DEFAULT '' NOT NULL;

;
CREATE INDEX talks_idx_conferences_id on talks (conferences_id);

;
ALTER TABLE talks ADD CONSTRAINT talks_fk_conferences_id FOREIGN KEY (conferences_id)
  REFERENCES conferences (conferences_id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

