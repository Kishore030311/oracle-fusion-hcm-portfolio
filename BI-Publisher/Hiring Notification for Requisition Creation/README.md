# Oracle Fusion HCM – Requisition Creation Notification

## Overview
This project demonstrates an Oracle Fusion HCM BI Publisher solution for automating requisition creation notifications.
The solution retrieves requisition, recruiter, hiring manager, and checklist information from Oracle Recruiting Cloud (created via HCM Data Loader) and uses BI Publisher bursting to send automated email notifications to the recruiter and hiring manager.

## Components

### 1. Data Query
Retrieves the requisition, phase/state, recruiter, hiring manager, allocated checklist details, and a generated deep link to the requisition. This forms the main dataset for the report.

### 2. Bursting Query
Defines the bursting recipients (TO/CC), sender, subject, template, and output format used to email the notification for each `ALLOCATED_CHECKLIST_ID`.

### 3. Event Trigger Query
Acts as a **bursting validation gate**. It checks whether matching data exists before the burst runs.
> If no data is found, the scheduled process completes as **Skipped** instead of **Failed** — this is expected behavior, not an error.

## Technologies
- Oracle Fusion HCM
- Oracle Recruiting Cloud (IRC)
- HCM Data Loader (HDL)
- BI Publisher
- SQL
- HCM Checklists
- BI Publisher Bursting
- Email Notifications

## Placeholders

| Placeholder | Replace with |
|---|---|
| `<FA_DOMAIN_NAME>` | Actual `DEPLOYED_DOMAIN_NAME` value in `ASK_DEPLOYED_DOMAINS` for your environment |
| `<CHECKLIST_ID_1>`, `<CHECKLIST_ID_2>` | Actual checklist ID(s) relevant to this notification |
| `<TO_EMAIL_LIST>` | Recipient email(s) for the notification |
| `<CC_EMAIL_LIST>` | CC recipient email(s) |
| `<SENDER_EMAIL>` | Sender/from address used by the bursting email channel |

## ⚠️ Disclaimer
This project is provided for **demonstration and educational purposes only**.
- All email addresses, checklist IDs, domain names, and other sensitive values have been replaced with dummy or parameterized values (e.g. `<TO_EMAIL_LIST>`, `<CHECKLIST_ID_1>`, `<FA_DOMAIN_NAME>`).
- Before using these queries in a real Oracle Fusion HCM environment, replace the parameterized fields with the appropriate values from your environment.
- Validate table structures, checklist IDs, deployed domain names, email configurations, and business rules according to your organization's requirements.
- Do not use the sample data provided in this repository for production processing.
