# Post-Project Report — Modern Secure M365 Baseline

## Executive summary
This project implemented a secure Microsoft 365 baseline plus an Azure Automation reporting layer to support ongoing operations. The tenant now has identity hardening, device compliance enforcement, mail flow guardrails, collaboration governance controls, and a lightweight compliance demo (labels + DLP + retention).

## What changed (high impact)
- Conditional Access policies for MFA, legacy auth block, and device compliance (scoped)
- Intune enrollment + compliance policy + baseline configuration profile
- Exchange mail flow rule to block external auto-forwarding
- Purview sensitivity labels and DLP demo policy
- Azure Automation runbooks scheduled for ongoing reporting
- Microsoft365DSC export baseline + drift detection workflow

## What is enforced
- MFA requirement (users)
- Legacy authentication blocked
- Device compliance requirement (admin/high-risk scope)
- External auto-forwarding blocked

## What is monitored
- Runbook-generated reports (license, CA inventory, sign-in failures, secure score, etc.)
- Drift detection using Microsoft365DSC snapshots

## Known risks / follow-ups
- Tighten CA scope after observing report-only results
- Add alerting/notifications for failed runbooks
- Expand DLP to additional sensitive info types as needed

## How to request changes
- Submit a change request describing the business need and impacted users
- Review risk/impact and validate in report-only where applicable
- Schedule change window and communicate via comms templates
