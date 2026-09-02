/* ============================================================================
   REQUISITION CREATION - BI PUBLISHER REPORT
   ----------------------------------------------------------------------------
   OVERVIEW:
   This report is triggered when a new Requisition is created via
   HCM DATA LOADER (HDL). The HDL load is what fires the BI Publisher
   BURSTING process below — bursting does NOT run for requisitions created
   manually through the UI, only for HDL-driven creation.

   SECTIONS IN THIS FILE:
     1. DATA QUERY          -> main dataset feeding the report/email content
     2. BURSTING QUERY       -> defines recipients/template used to send
                                the notification per ALLOCATED_CHECKLIST_ID
     3. EVENT TRIGGER QUERY  -> BURSTING VALIDATION GATE. Confirms matching
                                data exists before the burst runs. If NO
                                data is found, the scheduled process ends
                                as SKIPPED (not FAILED) — this is expected,
                                not an error condition.

   NOTE: Replace all <PLACEHOLDER> values below with real environment data
   (recipient emails, sender email, checklist IDs, domain name) before
   deploying to any BIP Data Model.
   ============================================================================ */


/* ---------------------------------------------------------------------------
   1. DATA QUERY
   --------------------------------------------------------------------------- */
SELECT
    REQ.REQUISITION_ID,
    REQ.REQUISITION_NUMBER                                             AS REQ_NUMBER,
    REQ.TITLE                                                          AS REQUISITION_TITLE,
    PHASE.NAME || '-' || STATES.NAME                                   AS REQUISITION_STATUS,
    TO_CHAR(REQ.CREATION_DATE, 'DD-Mon-YYYY HH:MI AM',
            'NLS_DATE_LANGUAGE = AMERICAN')                            AS CREATION_DATE,
    REC_NUM.PERSON_NUMBER                                              AS RECRUITER_PERSON_NUMBER,
    REC_NAME.DISPLAY_NAME                                              AS RECRUITER_NAME,
    REC_MAIL.EMAIL_ADDRESS                                             AS REC_EMAIL,
    REC_MAIL.EMAIL_TYPE                                                AS REC_MAIL_TYPE,
    HM_NUM.PERSON_NUMBER                                               AS HIRING_MANAGER_PERSON_NUMBER,
    HM_NAME.DISPLAY_NAME                                               AS HIRING_MANAGER_NAME,
    HM_MAIL.EMAIL_ADDRESS                                              AS HM_EMAIL,
    HM_MAIL.EMAIL_TYPE                                                 AS HM_MAIL_TYPE,
    PAC.ALLOCATED_CHECKLIST_ID,
    PAC.CHECKLIST_STATUS,
    PACTL.CHECKLIST_NAME                                               AS JOURNEY,
    (SELECT 'https://' || EXTERNAL_VIRTUAL_HOST
       FROM ASK_DEPLOYED_DOMAINS
      WHERE DEPLOYED_DOMAIN_NAME = '<FA_DOMAIN_NAME>')
        || '/fndSetup/faces/deeplink?objType=IRC_RECRUITING'
        || '&action=REQUISITION_DETAIL_RECRUITING_RESP'
        || '&objKey=RequisitionId=' || REQ.REQUISITION_ID             AS REQUISITION_DEEPLINK
FROM
    IRC_REQUISITIONS_VL          REQ,
    IRC_PHASES_VL                PHASE,
    IRC_STATES_VL                STATES,
    PER_ALL_PEOPLE_F             REC_NUM,
    PER_PERSON_NAMES_F           REC_NAME,
    PER_ALL_PEOPLE_F             HM_NUM,
    PER_PERSON_NAMES_F           HM_NAME,
    HRC_INTEGRATION_KEY_MAP      OBJ,
    PER_ALLOCATED_CHECKLISTS     PAC,
    PER_ALLOCATED_CHECKLISTS_TL  PACTL,
    PER_EMAIL_ADDRESSES          REC_MAIL,
    PER_EMAIL_ADDRESSES          HM_MAIL
WHERE 1 = 1
    AND REQ.CURRENT_STATE_ID  = STATES.STATE_ID
    AND REQ.CURRENT_PHASE_ID  = PHASE.PHASE_ID
    AND REQ.RECRUITER_ID      = REC_NUM.PERSON_ID
    AND REQ.RECRUITER_ID      = REC_NAME.PERSON_ID
    AND REQ.HIRING_MANAGER_ID = HM_NUM.PERSON_ID
    AND REQ.HIRING_MANAGER_ID = HM_NAME.PERSON_ID
    AND TRUNC(SYSDATE) BETWEEN REC_NUM.EFFECTIVE_START_DATE  AND REC_NUM.EFFECTIVE_END_DATE
    AND TRUNC(SYSDATE) BETWEEN REC_NAME.EFFECTIVE_START_DATE AND REC_NAME.EFFECTIVE_END_DATE
    AND TRUNC(SYSDATE) BETWEEN HM_NUM.EFFECTIVE_START_DATE   AND HM_NUM.EFFECTIVE_END_DATE
    AND TRUNC(SYSDATE) BETWEEN HM_NAME.EFFECTIVE_START_DATE  AND HM_NAME.EFFECTIVE_END_DATE
    AND REC_NAME.NAME_TYPE = 'GLOBAL'
    AND HM_NAME.NAME_TYPE  = 'GLOBAL'

    AND REQ.REQUISITION_ID   = OBJ.SURROGATE_ID
    AND OBJ.SOURCE_SYSTEM_ID = TO_CHAR(PAC.ALLOCATED_CHECKLIST_ID)
    AND PAC.CHECKLIST_STATUS = 'COM'
    AND OBJ.OBJECT_NAME      = 'Requisition'
    AND PAC.CHECKLIST_ID IN ('<CHECKLIST_ID_1>', '<CHECKLIST_ID_2>')

    AND REC_MAIL.PERSON_ID  = REC_NUM.PERSON_ID
    AND HM_MAIL.PERSON_ID   = HM_NUM.PERSON_ID
    AND REC_MAIL.EMAIL_TYPE = 'W1'
    AND HM_MAIL.EMAIL_TYPE  = 'W1'

    AND PAC.ALLOCATED_CHECKLIST_ID = PACTL.ALLOCATED_CHECKLIST_ID
    AND PACTL.LANGUAGE = 'US'

    AND (:RECRUITER IS NULL OR REC_NUM.PERSON_NUMBER = :RECRUITER)
    AND (:HIRING_MANAGER IS NULL OR HM_NUM.PERSON_NUMBER = :HIRING_MANAGER)
    AND (:ALLOCATED_CHECKLIST_ID IS NULL OR PAC.ALLOCATED_CHECKLIST_ID = :ALLOCATED_CHECKLIST_ID)

    AND REQ.CREATION_DATE >= SYSDATE - (30 / 1440)
    AND REQ.CREATION_DATE <  SYSDATE
;


/* ---------------------------------------------------------------------------
   2. BURSTING QUERY
   --------------------------------------------------------------------------- */
SELECT
    -- Bursting Columns
    PAC.ALLOCATED_CHECKLIST_ID                                          KEY,
    'BITemplate'                                                        TEMPLATE,
    'en-US'                                                             LOCALE,
    'HTML'                                                              OUTPUT_FORMAT,
    'Requisition Creation Regarding'                                    OUTPUT_NAME,
    'EMAIL'                                                             DEL_CHANNEL,
    /* CASE
        WHEN REC_MAIL.EMAIL_ADDRESS = HM_MAIL.EMAIL_ADDRESS
            THEN REC_MAIL.EMAIL_ADDRESS
        WHEN REC_MAIL.EMAIL_ADDRESS IS NOT NULL AND HM_MAIL.EMAIL_ADDRESS IS NOT NULL
            THEN REC_MAIL.EMAIL_ADDRESS || ',' || HM_MAIL.EMAIL_ADDRESS
        WHEN REC_MAIL.EMAIL_ADDRESS IS NOT NULL
            THEN REC_MAIL.EMAIL_ADDRESS
        WHEN HM_MAIL.EMAIL_ADDRESS IS NOT NULL
            THEN HM_MAIL.EMAIL_ADDRESS
        ELSE NULL
    END */
    '<TO_EMAIL_LIST>'                                                   PARAMETER1, --TO
    '<CC_EMAIL_LIST>'                                                   PARAMETER2, --CC
    '<SENDER_EMAIL>'                                                    PARAMETER3,
    'Requisition Creation - ' || REQ.TITLE || '-' || REQ.REQUISITION_NUMBER PARAMETER4,
    NULL                                                                 PARAMETER5,
    'False'                                                              PARAMETER6
FROM
    IRC_REQUISITIONS_VL          REQ,
    IRC_PHASES_VL                PHASE,
    IRC_STATES_VL                STATES,
    PER_ALL_PEOPLE_F             REC_NUM,
    PER_PERSON_NAMES_F           REC_NAME,
    PER_ALL_PEOPLE_F             HM_NUM,
    PER_PERSON_NAMES_F           HM_NAME,
    HRC_INTEGRATION_KEY_MAP      OBJ,
    PER_ALLOCATED_CHECKLISTS     PAC,
    PER_ALLOCATED_CHECKLISTS_TL  PACTL,
    PER_EMAIL_ADDRESSES          REC_MAIL,
    PER_EMAIL_ADDRESSES          HM_MAIL
WHERE 1 = 1
    AND REQ.CURRENT_STATE_ID  = STATES.STATE_ID
    AND REQ.CURRENT_PHASE_ID  = PHASE.PHASE_ID
    AND REQ.RECRUITER_ID      = REC_NUM.PERSON_ID
    AND REQ.RECRUITER_ID      = REC_NAME.PERSON_ID
    AND REQ.HIRING_MANAGER_ID = HM_NUM.PERSON_ID
    AND REQ.HIRING_MANAGER_ID = HM_NAME.PERSON_ID
    AND TRUNC(SYSDATE) BETWEEN REC_NUM.EFFECTIVE_START_DATE  AND REC_NUM.EFFECTIVE_END_DATE
    AND TRUNC(SYSDATE) BETWEEN REC_NAME.EFFECTIVE_START_DATE AND REC_NAME.EFFECTIVE_END_DATE
    AND TRUNC(SYSDATE) BETWEEN HM_NUM.EFFECTIVE_START_DATE   AND HM_NUM.EFFECTIVE_END_DATE
    AND TRUNC(SYSDATE) BETWEEN HM_NAME.EFFECTIVE_START_DATE  AND HM_NAME.EFFECTIVE_END_DATE
    AND REC_NAME.NAME_TYPE = 'GLOBAL'
    AND HM_NAME.NAME_TYPE  = 'GLOBAL'

    AND REQ.REQUISITION_ID   = OBJ.SURROGATE_ID
    AND OBJ.SOURCE_SYSTEM_ID = TO_CHAR(PAC.ALLOCATED_CHECKLIST_ID)
    AND PAC.CHECKLIST_STATUS = 'COM'
    AND OBJ.OBJECT_NAME      = 'Requisition'
    AND PAC.CHECKLIST_ID IN ('<CHECKLIST_ID_1>', '<CHECKLIST_ID_2>')

    AND REC_MAIL.PERSON_ID  = REC_NUM.PERSON_ID
    AND HM_MAIL.PERSON_ID   = HM_NUM.PERSON_ID
    AND REC_MAIL.EMAIL_TYPE = 'W1'
    AND HM_MAIL.EMAIL_TYPE  = 'W1'

    AND PAC.ALLOCATED_CHECKLIST_ID = PACTL.ALLOCATED_CHECKLIST_ID
    AND PACTL.LANGUAGE = 'US'

    AND (:RECRUITER IS NULL OR REC_NUM.PERSON_NUMBER = :RECRUITER)
    AND (:HIRING_MANAGER IS NULL OR HM_NUM.PERSON_NUMBER = :HIRING_MANAGER)
    AND (:ALLOCATED_CHECKLIST_ID IS NULL OR PAC.ALLOCATED_CHECKLIST_ID = :ALLOCATED_CHECKLIST_ID)

    AND REQ.CREATION_DATE >= SYSDATE - (30 / 1440)
    AND REQ.CREATION_DATE <  SYSDATE
;


/* ---------------------------------------------------------------------------
   3. EVENT TRIGGER QUERY (Bursting validation gate — no data => Skipped)
   --------------------------------------------------------------------------- */
SELECT 1
FROM DUAL
WHERE EXISTS (
    SELECT 1
    FROM
        IRC_REQUISITIONS_VL          REQ,
        IRC_PHASES_VL                PHASE,
        IRC_STATES_VL                STATES,
        PER_ALL_PEOPLE_F             REC_NUM,
        PER_PERSON_NAMES_F           REC_NAME,
        PER_ALL_PEOPLE_F             HM_NUM,
        PER_PERSON_NAMES_F           HM_NAME,
        HRC_INTEGRATION_KEY_MAP      OBJ,
        PER_ALLOCATED_CHECKLISTS     PAC,
        PER_ALLOCATED_CHECKLISTS_TL  PACTL,
        PER_EMAIL_ADDRESSES          REC_MAIL,
        PER_EMAIL_ADDRESSES          HM_MAIL
    WHERE 1 = 1
        AND REQ.CURRENT_STATE_ID  = STATES.STATE_ID
        AND REQ.CURRENT_PHASE_ID  = PHASE.PHASE_ID
        AND REQ.RECRUITER_ID      = REC_NUM.PERSON_ID
        AND REQ.RECRUITER_ID      = REC_NAME.PERSON_ID
        AND REQ.HIRING_MANAGER_ID = HM_NUM.PERSON_ID
        AND REQ.HIRING_MANAGER_ID = HM_NAME.PERSON_ID
        AND TRUNC(SYSDATE) BETWEEN REC_NUM.EFFECTIVE_START_DATE  AND REC_NUM.EFFECTIVE_END_DATE
        AND TRUNC(SYSDATE) BETWEEN REC_NAME.EFFECTIVE_START_DATE AND REC_NAME.EFFECTIVE_END_DATE
        AND TRUNC(SYSDATE) BETWEEN HM_NUM.EFFECTIVE_START_DATE   AND HM_NUM.EFFECTIVE_END_DATE
        AND TRUNC(SYSDATE) BETWEEN HM_NAME.EFFECTIVE_START_DATE  AND HM_NAME.EFFECTIVE_END_DATE
        AND REC_NAME.NAME_TYPE = 'GLOBAL'
        AND HM_NAME.NAME_TYPE  = 'GLOBAL'

        AND REQ.REQUISITION_ID   = OBJ.SURROGATE_ID
        AND OBJ.SOURCE_SYSTEM_ID = TO_CHAR(PAC.ALLOCATED_CHECKLIST_ID)
        AND PAC.CHECKLIST_STATUS = 'COM'
        AND OBJ.OBJECT_NAME      = 'Requisition'
        AND PAC.CHECKLIST_ID IN ('<CHECKLIST_ID_1>', '<CHECKLIST_ID_2>')

        AND REC_MAIL.PERSON_ID  = REC_NUM.PERSON_ID
        AND HM_MAIL.PERSON_ID   = HM_NUM.PERSON_ID
        AND REC_MAIL.EMAIL_TYPE = 'W1'
        AND HM_MAIL.EMAIL_TYPE  = 'W1'

        AND PAC.ALLOCATED_CHECKLIST_ID = PACTL.ALLOCATED_CHECKLIST_ID
        AND PACTL.LANGUAGE = 'US'

        AND REQ.CREATION_DATE >= SYSDATE - (30 / 1440)
        AND REQ.CREATION_DATE <  SYSDATE
)
