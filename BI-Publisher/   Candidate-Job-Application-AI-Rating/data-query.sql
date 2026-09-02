/*
===============================================================================
Project     : Oracle Fusion HCM – Recruiting / Candidate Selection
Component   : BI Publisher Data Query
Purpose     : Retrieve candidate submissions with AI-generated screening
              scores (skills, experience, education, profile, overall) and
              ranking for a given requisition, with optional filters by
              requisition or candidate
Environment : Oracle Fusion HCM (Recruiting Cloud)
===============================================================================
===============================================================================
DISCLAIMER
===============================================================================
This SQL has been sanitized for portfolio/demo purposes.
Replace parameterized values such as:
    :REQUISITION_NUMBER
    :REQUISITION_TITLE
    :CANDIDATE_NUMBER
    :CANDIDATE_NAME
with the appropriate values from your Oracle Fusion HCM environment
before executing the query.
Always validate the query against your environment and business requirements.
===============================================================================
*/
SELECT
    CAN.CANDIDATE_NUMBER       AS CANDIDATE_NUMBER,
    NAME.FULL_NAME             AS CANDIDATE_NAME,
    REQ.REQUISITION_NUMBER     AS REQUISITION_NUMBER,
    REQTL.TITLE                AS REQUISITION_TITLE,
    SCORE.SKILLS_AI_SCORE      AS SKILL_RATINGS,
    SCORE.EXPERIENCE_AI_SCORE  AS EXPERIENCE_RATINGS,
    SCORE.EDUCATION_AI_SCORE   AS EDUCATION_RATINGS,
    SCORE.PROFILE_AI_SCORE     AS PROFILE_RATINGS,
    SCORE.OVERALL_SCORE        AS OVERALL_RATINGS,
    SCORE.PROFILE_SUMMARY      AS PROFILE_SUMMARY,
    SUB.CURRENT_RANK           AS RANK

FROM
    IRC_SUBMISSIONS        SUB,
    IRC_CANDIDATES         CAN,
    PER_PERSON_NAMES_F     NAME,
    IRC_REQUISITIONS_B     REQ,
    IRC_REQUISITIONS_TL    REQTL,
    IRC_APPLICANT_SCORES   SCORE

WHERE 1=1
    AND SUB.PERSON_ID = CAN.PERSON_ID
    AND CAN.PERSON_ID = NAME.PERSON_ID
    AND TRUNC(SYSDATE) BETWEEN NAME.EFFECTIVE_START_DATE AND NAME.EFFECTIVE_END_DATE
    AND NAME.NAME_TYPE = 'GLOBAL'

    AND SUB.REQUISITION_ID = REQ.REQUISITION_ID
    AND REQ.REQUISITION_ID = REQTL.REQUISITION_ID
    AND REQTL.LANGUAGE = 'US'

    AND SUB.REQUISITION_ID = SCORE.REQUISITION_ID(+)
    AND SUB.PERSON_ID      = SCORE.PERSON_ID(+)

    AND ( :REQUISITION_NUMBER IS NULL OR REQ.REQUISITION_NUMBER = :REQUISITION_NUMBER )
    AND ( :REQUISITION_TITLE  IS NULL OR REQTL.TITLE = :REQUISITION_TITLE )
    AND ( :CANDIDATE_NUMBER   IS NULL OR CAN.CANDIDATE_NUMBER = :CANDIDATE_NUMBER )
    AND ( :CANDIDATE_NAME     IS NULL OR NAME.FULL_NAME = :CANDIDATE_NAME )

ORDER BY
    SUB.CURRENT_RANK,
    CAN.CANDIDATE_NUMBER,
    REQ.REQUISITION_NUMBER
