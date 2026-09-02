/*
===============================================================================
Project     : Oracle Fusion HCM – Overseas Employee Onboarding Notification
Component   : BI Publisher Bursting Query
Purpose     : Generate bursting control data (recipient, template, and email
              parameters) to trigger onboarding notification for overseas
              hires based on questionnaire arrival date response
Environment : Oracle Fusion HCM
===============================================================================
===============================================================================
DISCLAIMER
===============================================================================
This SQL has been sanitized for portfolio/demo purposes.
Replace parameterized values such as:
    :QUESTIONNAIRE_ID
    :QUESTION_ID
    :CC_EMAIL_LIST
    :SENDER_EMAIL
    :LOCATION_NAME
    :TEST_PERSON_NUMBERS
with the appropriate values from your Oracle Fusion HCM environment
before executing the query.
Always validate the query against your environment and business requirements.
===============================================================================
*/
SELECT
    /* Bursting Key */
    PAPF.PERSON_NUMBER AS KEY,

    /* BI Publisher Template */
    'BITemplate' AS TEMPLATE,

    /* Language */
    'en-US' AS LOCALE,

    /* Output Format */
    'HTML' AS OUTPUT_FORMAT,

    /* Output File Name */
    'Overseas Employee Onboarding' AS OUTPUT_NAME,

    /* Delivery Channel */
    'EMAIL' AS DEL_CHANNEL,

    /* Employee Email / Receiver */
    PEA.EMAIL_ADDRESS AS PARAMETER1,

    /* CC / Additional Recipients */
    'hr-team@example.com,hr-operations@example.com' AS PARAMETER2,

    /* Sender */
    'noreply@example.com' AS PARAMETER3,

    /* Email Subject */
    'Welcome to Qatar - ' || PPNF.FULL_NAME AS PARAMETER4,

    /* Additional Bursting Parameter */
    'False' AS PARAMETER6

FROM
    PER_ALL_PEOPLE_F PAPF,
    PER_PERSON_NAMES_F PPNF,
    PER_EMAIL_ADDRESSES PEA,
    PER_ALLOCATED_CHECKLISTS PAC,
    PER_ALLOCATED_TASKS PAT,
    HRQ_QSTNR_PARTICIPANTS HQP,
    HRQ_QSTNR_RESPONSES HQR,
    HRQ_QSTN_RESPONSES HQSR,
    HRQ_QSTNR_QUESTIONS HQQ

WHERE 1 = 1

    AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE

    AND PAPF.PERSON_ID = PPNF.PERSON_ID

    AND TRUNC(SYSDATE) BETWEEN PPNF.EFFECTIVE_START_DATE AND PPNF.EFFECTIVE_END_DATE

    AND PPNF.NAME_TYPE = 'GLOBAL'

    AND PAPF.PERSON_ID = PEA.PERSON_ID

    AND PAC.PERSON_ID = PAPF.PERSON_ID

    AND PAC.ALLOCATED_CHECKLIST_ID = PAT.ALLOCATED_CHECKLIST_ID

    AND PAT.QUESTIONNAIRE_ID = :QUESTIONNAIRE_ID

    AND HQP.PARTICIPANT_ID = TO_CHAR(PAT.ALLOCATED_TASK_ID)

    AND HQP.SUBJECT_ID = PAPF.PERSON_ID

    AND PAT.QUESTIONNAIRE_ID = HQP.QUESTIONNAIRE_ID

    AND HQR.QSTNR_PARTICIPANT_ID = HQP.QSTNR_PARTICIPANT_ID

    AND HQR.LATEST_ATTEMPT_FLAG = 'Y'

    AND HQSR.QSTNR_RESPONSE_ID = HQR.QSTNR_RESPONSE_ID

    AND HQSR.ANSWER_TEXT IS NOT NULL

    AND HQQ.QSTNR_QUESTION_ID = HQSR.QSTNR_QUESTION_ID

    AND HQQ.QUESTION_ID = :QUESTION_ID

    AND REGEXP_LIKE(HQSR.ANSWER_TEXT,'^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$')

    AND TRUNC(SYSDATE) = TO_DATE(HQSR.ANSWER_TEXT, 'YYYY-MM-DD') + 1
