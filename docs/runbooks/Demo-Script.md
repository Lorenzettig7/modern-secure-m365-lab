# Demo Script — Modern Secure M365 Lab

## 0) Setup (1–2 minutes)
- Sign in as `admin.global` (daily admin)
- Have 1 example report file ready in `evidence/reports/`

## 1) 60-second architecture overview
- M365 tenant baseline (Entra + Intune + Exchange + Teams/SP + Purview)
- Azure Automation Account with Managed Identity
- Scheduled reporting + DSC drift detection

## 2) Conditional Access + sign-in logs
- Show CA policies list
- Open a sign-in log entry and point out applied CA policies

## 3) Intune compliance → CA device requirement
- Show Intune compliance policy
- Show a managed device compliance state
- Explain how CA enforces “compliant device” access

## 4) Exchange security
- Show mail flow rule: block external auto-forwarding
- (Optional) Show quarantine view

## 5) Purview
- Show sensitivity labels
- Show DLP policy
- Show a safe DLP test result (fake SSN triggers)

## 6) Azure Automation runbooks
- Show runbooks list and schedules
- Open a successful job run and show job output

## 7) Generated report + drift proof
- Open one CSV report (license / sign-in failures / CA inventory)
- Show DSC baseline/current export folder
- Show drift diff output proving change detection

## 8) Close
- Point to repo deliverables:
  - `scripts/` runbooks + bootstrap
  - `docs/client-artifacts/` client packet
  - `docs/runbooks/` ops runbooks + demo script
  - `docs/rca/` RCA template
  - `evidence/` exports/reports/screenshots
