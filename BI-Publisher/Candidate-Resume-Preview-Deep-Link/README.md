# Oracle Fusion HCM – Candidate Resume Preview (Deep Link)

## Overview
This project demonstrates an Oracle Fusion HCM Recruiting Cloud BI Publisher solution for generating a deep link that allows recruiters to preview a candidate's resume directly in the browser, instead of downloading the file.
The query retrieves requisition and candidate details along with a dynamically generated resume preview URL, built using Oracle's content server (WebCenter Content / IdcService) integration.

## Technologies
- Oracle Fusion HCM (Recruiting Cloud)
- BI Publisher
- SQL
- FND Attachments / Document Management
- WebCenter Content (Content Server) Integration
- IRC Requisitions and Submissions

## Feature Notes
- **Resume Preview** is a newer Oracle-delivered feature enabling inline resume viewing instead of a mandatory download.
- Inline preview is supported only for certain file formats (e.g., **PDF**). Other formats (e.g., **DOCX**) will still download instead of previewing.
- Previewing or downloading resumes/attachments requires the **User Attachment Administrator** role, which grants full access to search, view, and download documents and candidate resumes stored on the content server. Users without this privilege cannot use the generated preview link.

## ⚠️ Disclaimer
This project is provided for **demonstration and educational purposes only**.
- All employee information, email addresses, IDs, and other sensitive values have been replaced with dummy or parameterized values.
- Before using these queries in a real Oracle Fusion HCM environment, replace the parameterized fields with the appropriate values from your environment.
- Validate table structures, questionnaire IDs, question IDs, email configurations, and business rules according to your organization's requirements.
- Do not use the sample data provided in this repository for production processing.
