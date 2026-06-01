PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS assessments;
DROP TABLE IF EXISTS participants;

CREATE TABLE participants (
    participant_id INTEGER PRIMARY KEY,
    sex TEXT NOT NULL CHECK (sex IN ('F', 'M')),
    birth_year INTEGER NOT NULL CHECK (birth_year BETWEEN 1900 AND 2100)
);

CREATE TABLE assessments (
    participant_id INTEGER NOT NULL,
    wave INTEGER NOT NULL CHECK (wave BETWEEN 1 AND 4),
    assessment_date TEXT NOT NULL,
    bmi REAL CHECK (
        bmi IS NULL OR bmi BETWEEN 10 AND 80
    ),
    systolic_bp REAL CHECK (
        systolic_bp IS NULL OR systolic_bp BETWEEN 60 AND 250
    ),
    questionnaire_score REAL CHECK (
        questionnaire_score IS NULL OR
        questionnaire_score BETWEEN 0 AND 100
    ),

    PRIMARY KEY (participant_id, wave),

    FOREIGN KEY (participant_id)
        REFERENCES participants(participant_id)
);

CREATE INDEX idx_assessments_participant
    ON assessments(participant_id);

CREATE INDEX idx_assessments_wave
    ON assessments(wave);

CREATE INDEX idx_assessments_date
    ON assessments(assessment_date);