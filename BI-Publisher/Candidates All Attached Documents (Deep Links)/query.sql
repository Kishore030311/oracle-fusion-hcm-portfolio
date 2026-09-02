/*
================================================================================
  SCRIPT NAME : candidates All Attached Documents.sql
  MODULE      : Oracle Fusion HCM / Oracle Recruiting Cloud (IRC)
--------------------------------------------------------------------------------
  PURPOSE:
    Builds a per-candidate "document status" report for Oracle Recruiting
    Cloud. For each active worker with an associated candidate record, the
    query returns the Candidate Number and generates direct download links
    (via WebCenter Content / UCM) for every onboarding-related document:
    resume, visa, passport, certificates, signed forms, contracts, etc.

  DISCLAIMER:
    ⚠️ THIS SCRIPT IS PROVIDED FOR DEMONSTRATION / EDUCATIONAL PURPOSES ONLY.
    All document type names, task names, and attachment categories below
    have been REPLACED WITH DUMMY / PLACEHOLDER VALUES (shown in
    <ANGLE_BRACKETS>). These placeholders do NOT reflect any real
    environment, company, or production configuration.

    Before using this script in any environment, you MUST:
      1. Replace every <PLACEHOLDER> below with the actual document type,
         task name, or attachment category configured in YOUR Oracle
         Fusion HCM / ORC instance.
      2. Validate all table/view names, statuses, and effective-dated
         logic against your own data model and business rules.
      3. Review and approve the query for performance, security, and data
         privacy (it exposes direct document download URLs) before
         deploying to any non-sandbox environment.

    Do NOT run this script as-is against a production instance, and do NOT
    treat the sample values here as real configuration or real data.
================================================================================
*/

WITH
-- Returns a WebCenter Content (UCM) download link for a document attached
-- to a specific onboarding checklist TASK (Document of Record type tasks).
-- P_TASK_NAME must match the task name configured in your Journey/Checklist.
FUNCTION GET_TASK_DOC_LINK( P_PERSON_NUMBER VARCHAR2,P_TASK_NAME VARCHAR2)
RETURN VARCHAR2 AS
    LV_LINK    VARCHAR2(4000);
BEGIN
  SELECT
       CASE WHEN FDT.DM_VERSION_NUMBER IS NOT NULL AND FDT.DM_DOCUMENT_ID IS NOT NULL THEN
           (SELECT 'https://' || EXTERNAL_VIRTUAL_HOST
              FROM FUSION.ASK_DEPLOYED_DOMAINS
             WHERE DEPLOYED_DOMAIN_NAME = 'FADomain')
        || '/cs/idcplg?IdcService=GET_FILE'
        || CHR(38) || 'dID=' || FDT.DM_VERSION_NUMBER
        || '&dDocName='      || FDT.DM_DOCUMENT_ID
        || '&allowInterrupt=1'
       ELSE NULL END
    INTO LV_LINK
    FROM PER_ALL_PEOPLE_F             PAPF,
         PER_ALLOCATED_CHECKLISTS     AC,
         PER_ALLOCATED_CHECKLISTS_TL  ACT,
         PER_ALLOCATED_TASKS          ATC,
         PER_ALLOCATED_TASKS_TL       ATT,
         FND_ATTACHED_DOCUMENTS       AAD,
         FND_DOCUMENTS_TL             FDT
    WHERE 1=1
      AND AC.PERSON_ID = PAPF.PERSON_ID
      AND AC.ALLOCATED_CHECKLIST_ID = ACT.ALLOCATED_CHECKLIST_ID
      AND AC.ALLOCATED_CHECKLIST_ID = ATC.ALLOCATED_CHECKLIST_ID
      AND ATC.ALLOCATED_TASK_ID = ATT.ALLOCATED_TASK_ID
      AND TO_CHAR(ATC.ATT_DOCUMENTS_OF_RECORD_ID) = AAD.PK1_VALUE
      AND AAD.DOCUMENT_ID = FDT.DOCUMENT_ID
      AND AAD.ENTITY_NAME = 'HR_DOCUMENTS_OF_RECORD'
      AND ATT.LANGUAGE = 'US'
      AND ACT.LANGUAGE = 'US'
      AND FDT.LANGUAGE = 'US'
      AND PAPF.PERSON_NUMBER = P_PERSON_NUMBER
      AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
      AND ATT.TASK_NAME = P_TASK_NAME
      AND ROWNUM = 1;
    RETURN LV_LINK;
  EXCEPTION
      WHEN OTHERS THEN
       RETURN NULL;
   END;

-- Returns a UCM download link for a candidate ATTACHMENT (e.g. resume)
-- captured during recruiting, filtered by attachment category name.
FUNCTION GET_ATTACHMENT_LINK( P_PERSON_NUMBER IN VARCHAR2,P_CATEGORY_NAME IN VARCHAR2)
RETURN VARCHAR2 AS
    LV_LINK        VARCHAR2(4000);
BEGIN
  SELECT
       CASE WHEN FDT2.DM_VERSION_NUMBER IS NOT NULL AND FDT2.DM_DOCUMENT_ID IS NOT NULL THEN
           (SELECT 'https://' || EXTERNAL_VIRTUAL_HOST
              FROM FUSION.ASK_DEPLOYED_DOMAINS
             WHERE DEPLOYED_DOMAIN_NAME = 'FADomain')
        || '/cs/idcplg?IdcService=GET_FILE'
        || CHR(38) || 'dID='  || FDT2.DM_VERSION_NUMBER
        || '&dDocName='       || FDT2.DM_DOCUMENT_ID
        || '&allowInterrupt=1'
       ELSE NULL END
    INTO LV_LINK
    FROM FND_ATTACHED_DOCUMENTS FAD,
         FND_DOCUMENTS_TL FDT2,
         IRC_CANDIDATES IC,
         PER_ALL_PEOPLE_F PAPF
     WHERE FAD.PK1_VALUE = TO_CHAR(IC.PERSON_ID)
       AND FAD.ENTITY_NAME = 'IRC_CANDIDATES'
       AND FAD.DOCUMENT_ID = FDT2.DOCUMENT_ID
       AND FDT2.LANGUAGE = 'US'
       AND FAD.CATEGORY_NAME = P_CATEGORY_NAME
       AND IC.PERSON_ID = PAPF.PERSON_ID
       AND PAPF.PERSON_NUMBER = P_PERSON_NUMBER
       AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
       AND ROWNUM = 1;
    RETURN LV_LINK;
  EXCEPTION
      WHEN OTHERS THEN
       RETURN NULL;
   END;

-- Returns a UCM download link for a "Document of Record" (HR document),
-- filtered by document type.
FUNCTION GET_DOCUMENT_LINK(
    P_PERSON_NUMBER IN VARCHAR2,
    P_DOCUMENT_TYPE IN VARCHAR2
)
RETURN VARCHAR2
AS
    LV_LINK VARCHAR2(4000);
BEGIN
    SELECT
       CASE WHEN FDT2.DM_VERSION_NUMBER IS NOT NULL AND FDT2.DM_DOCUMENT_ID IS NOT NULL THEN
           (SELECT 'https://' || EXTERNAL_VIRTUAL_HOST
              FROM FUSION.ASK_DEPLOYED_DOMAINS
             WHERE DEPLOYED_DOMAIN_NAME = 'FADomain')
        || '/cs/idcplg?IdcService=GET_FILE'
        || CHR(38) || 'dID=' || FDT2.DM_VERSION_NUMBER
        || '&dDocName=' || FDT2.DM_DOCUMENT_ID
        || '&allowInterrupt=1'
       ELSE NULL END
    INTO LV_LINK
    FROM FND_ATTACHED_DOCUMENTS FAD,
         FND_DOCUMENTS_TL FDT2,
         PER_ALL_PEOPLE_F PAPF,
         HR_DOCUMENTS_OF_RECORD DOR,
         HR_DOCUMENT_TYPES_TL DTP

    WHERE 1=1
      AND DOR.PERSON_ID = PAPF.PERSON_ID
      AND DOR.DOCUMENT_TYPE_ID = DTP.DOCUMENT_TYPE_ID
      AND TO_CHAR(DOR.DOCUMENTS_OF_RECORD_ID) = FAD.PK1_VALUE
      AND FAD.DOCUMENT_ID = FDT2.DOCUMENT_ID
	  AND fad.entity_name = 'HR_DOCUMENTS_OF_RECORD'
      AND FDT2.LANGUAGE = 'US'
	  AND DTP.LANGUAGE = 'US'
      AND DTP.DOCUMENT_TYPE = P_DOCUMENT_TYPE
      AND PAPF.PERSON_NUMBER = P_PERSON_NUMBER
      AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
      AND ROWNUM = 1;

    RETURN LV_LINK;
  EXCEPTION
      WHEN OTHERS THEN
       RETURN NULL;
   END;



SELECT	 IC.CANDIDATE_NUMBER,

	-- Candidate resume (recruiting attachment category)
	GET_ATTACHMENT_LINK( PAPF.PERSON_NUMBER, '<ATTACHMENT_CATEGORY_RESUME>') AS RESUME_LINK,

	-- Documents of Record (replace each <DOCUMENT_TYPE_...> with your configured Document Type name)
	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_VISA>') AS VISA_COPY,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_PASSPORT>') AS PASSPORT_LINK,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_EMPLOYMENT_CERT>') AS EMPLOYMENT,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_MARRIAGE_CERT>') AS MARRIAGE_CERTIFICATE,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_PHOTO>') AS PHOTO,

	-- Checklist TASK attachments (replace each <TASK_NAME_...> with your configured Task name)
	GET_TASK_DOC_LINK(PAPF.PERSON_NUMBER,'<TASK_NAME_EDUCATION_CERT>') AS EDUCATIONAL_CERTIFICATES,

	GET_TASK_DOC_LINK(PAPF.PERSON_NUMBER,'<TASK_NAME_POLICE_CLEARANCE>') AS POLICE_CLEARANCE,

	GET_TASK_DOC_LINK(PAPF.PERSON_NUMBER,'<TASK_NAME_MEDICAL_CERT>') AS MEDICAL_CERTIFICATE,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_EMPLOYMENT_CONTRACT>') AS EMPLOYMENT_CONTRACT,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_CODE_OF_CONDUCT>') AS CODE_OF_CONDUCT,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_PARTICULAR_FORM>') AS PARTICULAR_FORM,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_SIGNED_OFFER>') AS SIGNED_OFFER_LINK,

    GET_DOCUMENT_LINK(PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_SIGNED_JD>') AS SIGNED_JD_LINK,

	GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_CONFLICT_OF_INTEREST>')  AS CONFLICT_INTERST_FORM,

    GET_DOCUMENT_LINK (PAPF.PERSON_NUMBER, '<DOCUMENT_TYPE_EMPLOYMENT_APPLICATION>') AS EMPLOYMENT_APPLICATION_FORM

FROM
    PER_ALL_PEOPLE_F            PAPF,
    PER_ALL_ASSIGNMENTS_M       PAAM,
	IRC_CANDIDATES              IC

WHERE 1=1
    AND PAAM.PERSON_ID              = PAPF.PERSON_ID
	AND IC.PERSON_ID                = PAPF.PERSON_ID
    AND PAAM.ASSIGNMENT_TYPE        IN('P','E','C')
    AND PAAM.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
    AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
    AND TRUNC(SYSDATE) BETWEEN PAAM.EFFECTIVE_START_DATE AND PAAM.EFFECTIVE_END_DATE
	--AND PAPF.PERSON_NUMBER=:P_PERSON_NUMBER
