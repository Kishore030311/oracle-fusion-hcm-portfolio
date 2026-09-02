/*
===============================================================================
Project     : Oracle Fusion HCM – Recruiting / Candidate Resume Preview
Component   : BI Publisher Data Query
Purpose     : Retrieve requisition and candidate details along with a
              deep link to preview the candidate's resume directly in
              the browser, instead of downloading it
Environment : Oracle Fusion HCM (Recruiting Cloud)
===============================================================================
NOTES
===============================================================================
- Resume Preview is a newer Oracle-delivered feature that allows recruiters
  to preview a candidate's resume inline via a generated deep link, rather
  than downloading the file.
- Inline preview is only supported for certain file formats (e.g., PDF).
  Other formats (e.g., DOCX) will still trigger a file download instead
  of an inline preview.
- Access to preview or download resumes/attachments requires the
  'User Attachment Administrator' role/privilege, which provides full
  access to search, view, and download documents and candidate resumes
  stored on the content server. Users without this privilege will not
  be able to use the generated link.
===============================================================================
DISCLAIMER
===============================================================================
This SQL has been sanitized for portfolio/demo purposes.
- No hardcoded domains, employee data, or environment-specific values
  are present; the resume preview URL is built dynamically from
  ASK_DEPLOYED_DOMAINS at query runtime.
Always validate role/privilege assignments, document categories, and
attachment configurations against your own Oracle Fusion HCM environment
before using this query.
===============================================================================
*/
WITH
  FUNCTION GET_PERSON_NAME(P_PERSON_ID NUMBER, P_NAME_TYPE VARCHAR2) RETURN VARCHAR2 AS
    LV_PERSON_NAME VARCHAR2(200);
  BEGIN
    SELECT DISPLAY_NAME
    INTO LV_PERSON_NAME
    FROM PER_PERSON_NAMES_F
    WHERE  1=1
    AND TRUNC(SYSDATE) BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
    AND NAME_TYPE  = P_NAME_TYPE
    AND PERSON_ID  = P_PERSON_ID;
    RETURN LV_PERSON_NAME;
  EXCEPTION
    WHEN OTHERS THEN RETURN ' ';
  END;
SELECT
     CAND.CANDIDATE_NUMBER
    ,REQ.REQUISITION_NUMBER
    ,CASE
        WHEN TRACK.DM_VERSION_NUMBER IS NOT NULL
        THEN
            'https://' ||
            (SELECT EXTERNAL_VIRTUAL_HOST
             FROM ASK_DEPLOYED_DOMAINS
             WHERE EXTERNAL_VIRTUAL_HOST IS NOT NULL
             AND EXTERNAL_VIRTUAL_HOST LIKE '%.fa.%'
             AND ROWNUM = 1) ||
            '/cs/idcplg?IdcService=GET_FILE' ||
            '&dID=' || TRACK.DM_VERSION_NUMBER ||
            '&dDocName=' || TRACK.DM_DOCUMENT_ID ||
            '&allowInterrupt=1' ||
            '&IsJavaScriptEnabled=1' ||
            '&noSaveAs=1' ||
            '&inline=1'
        ELSE 'No Resume Uploaded'
     END                                          AS RESUME_PREVIEW_LINK
FROM
     IRC_REQUISITIONS_VL	REQ
    ,IRC_SUBMISSIONS	SUB
    ,IRC_CANDIDATES	CAND
    ,HR_ALL_POSITIONS_F_VL	POS
    ,FND_DOCUMENTS_TL	DOC
    ,FND_ATTACHED_DOCUMENTS	ATTACH
    ,FND_FILE_UPLOAD_TRACKERS TRACK
    ,FND_DOCUMENT_CATEGORIES_VL CAT
WHERE 1=1
AND CAND.PERSON_ID = SUB.PERSON_ID
AND POS.POSITION_ID = REQ.POSITION_ID
AND POS.ACTIVE_STATUS = 'A'
AND TRUNC(SYSDATE) BETWEEN POS.EFFECTIVE_START_DATE AND POS.EFFECTIVE_END_DATE
AND SUB.REQUISITION_ID = REQ.REQUISITION_ID
AND ATTACH.PK1_VALUE(+) = TO_CHAR(CAND.PERSON_ID)
AND ATTACH.ENTITY_NAME(+) = 'IRC_CANDIDATES'
AND ATTACH.CATEGORY_NAME(+) = 'IRC_CANDIDATE_RESUME'
AND DOC.DOCUMENT_ID(+) = ATTACH.DOCUMENT_ID
AND DOC.LANGUAGE(+) = 'US'
AND CAT.CATEGORY_NAME(+) = ATTACH.CATEGORY_NAME
AND TRACK.DOCUMENT_ID(+) = DOC.DOCUMENT_ID
AND TRACK.DM_VERSION_NUMBER IS NOT NULL
ORDER BY CAND.CANDIDATE_NUMBER
