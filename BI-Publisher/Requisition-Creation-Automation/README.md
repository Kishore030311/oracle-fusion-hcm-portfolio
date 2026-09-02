# Oracle Fusion HCM – Job Requisition Data Extraction for HDL Loading

## Overview
This project retrieves job requisition data from a completed Journey/Checklist in Oracle Fusion HCM and prepares it for automated loading via **HCM Data Loader (HDL)**.
The data is extracted using **HCM Extract**, transformed through SQL, and formatted into a `.dat` file using an **e-Text template**, which HDL then consumes to create Job Requisitions and their associated Hiring Teams.

## Components

### 1. JobRequisition Query
Builds the core `JobRequisition` HDL business object record from checklist/task attribute data — covering position selection (existing vs. new), requisition title, department, organization, job, grade, cost center, recruiter, hiring manager, business unit, legal employer, and other requisition-level attributes. Includes helper functions to resolve department names, job names, grade names, cost centers, and candidate selection process codes from underlying HR/Payroll tables. Excludes checklists that have already been loaded (checked against `HRC_INTEGRATION_KEY_MAP`) and auto-generates the next available `REQUISITIONNUMBER`.

### 2. HiringTeam Query
Builds the `HiringTeam` HDL business object record by unpivoting collaborator and manager attributes captured during checklist tasks. Produces one row per hiring team member (`ORA_HIRING_TEAM_COLLABORATOR` or a custom manager type), linked to the same requisition number generated in the JobRequisition query.

### 3. e-Text Template
Formats the extracted query output into the `.dat` file structure required by HDL for the `JobRequisition` and `HiringTeam` business objects.

## Technologies
- Oracle Fusion HCM
- HCM Extract
- HCM Data Loader (HDL)
- e-Text Template
- SQL / PL-SQL (WITH-clause functions, analytic functions)
- HR Journeys / Checklists (`PER_ALLOCATED_CHECKLISTS`, `PER_ALLOCATED_TASKS`)
- Oracle Recruiting Cloud (IRC)

## Process Flow
1. Recruiter/Hiring Manager completes the onboarding **Journey/Checklist** for a new requisition request (Position Selection, TA Manager Alignment, Intake Meeting, etc.).
2. **HCM Extract** runs the JobRequisition and HiringTeam queries against completed (`CHECKLIST_STATUS = 'COM'`) checklists not yet loaded into `HRC_INTEGRATION_KEY_MAP`.
3. The **e-Text template** formats the extracted rows into the `.dat` file layout expected by HDL.
4. **HCM Data Loader** consumes the `.dat` file to create the `JobRequisition` and `HiringTeam` records in Oracle Recruiting Cloud.
5. Once loaded, the checklist's `ALLOCATED_CHECKLIST_ID` is recorded in `HRC_INTEGRATION_KEY_MAP`, preventing duplicate loading on subsequent extract runs.

## Extract Creation Instructions
For guidance on initiating HCM Data Loader against HCM Extract–generated files (the mechanism used in Steps 3–4 of the Process Flow above), refer to Oracle's official tutorial:

[Initiate HCM Data Loader for HCM Extract Generated Files](https://docs.oracle.com/en/cloud/saas/tutorial-hdl-extract-flow/)

This resource walks through configuring the HCM Extract delivery options and the corresponding HDL load flow so that files land automatically in the UCM location HDL monitors, rather than requiring manual upload of the `.dat` file.

## Placeholders / Environment-Specific Values

| Item | Notes |
|---|---|
| `<CHECKLIST_ID>` | Actual checklist ID for the onboarding journey in your environment |
| `<TASK_NAME_TAM_1>`, `<TASK_NAME_TAM_2>` | Task names for TA Manager alignment/approval steps |
| `<TASK_NAME_INTAKE_1>` … `<TASK_NAME_INTAKE_4>` | Task names for intake meeting scheduling steps |
| `<TASK_NAME_POSITION_SELECTION>` | Task name for the position selection step |
| `<TASK_NAME_JOB_DESC>` | Task name for the job description/position creation step |
| `<FASTFORMULA_USER_TABLE>` / `<FASTFORMULA_USER_COLUMN>` | Fast Formula user table/column names used to resolve candidate selection process |
| `<HIRING_MANAGER_ROLE_NAME>` | Custom role name used to identify the Hiring Manager |
| `<SOURCE_SYSTEM_OWNER>` | `SOURCESYSTEMOWNER` value expected by HDL |

## ⚠️ Disclaimer
This project is provided for **demonstration and educational purposes only**.
- Checklist IDs, task names, user table/column names, custom role names, and other configuration-specific values have been replaced with placeholders and must be substituted with values from your own environment before use.
- Validate table structures, checklist/task names, business unit and organization mappings, and HDL business object requirements according to your organization's requirements.
- Do not use the sample data or configuration values provided in this repository for production processing.
