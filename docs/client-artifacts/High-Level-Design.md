# High-Level Design (HLD) — Modern Secure M365 Baseline

## Goals
- Establish a secure, supportable Microsoft 365 baseline
- Reduce account takeover risk (MFA + CA + legacy auth blocks)
- Improve endpoint posture (Intune enrollment + compliance)
- Harden mail flow and collaboration sharing
- Add repeatable ops reporting and drift detection

## Identity & Access (Entra)
- Break-glass account excluded from CA
- Conditional Access:
  - Require MFA for users
  - Block legacy authentication
  - Require compliant device (admin / high-risk scope)
- Least-privilege admin model and role assignment matrix

## Endpoint (Intune)
- Enrollment scope + restrictions
- Windows compliance policy (password + encryption + baseline requirements)
- Baseline configuration profile (Defender/Firewall/SmartScreen)

## Email security (Exchange / Defender)
- Anti-phish + anti-spam baseline
- Safe Links / Safe Attachments (if licensed)
- Mail flow rule: block external auto-forwarding
- Email auth plan (SPF/DKIM/DMARC)

## Collaboration governance (Teams/SharePoint/OneDrive)
- External sharing baseline
- Naming convention and site/team ownership
- “Before/after” structure to show governance impact

## Compliance (Purview)
- Sensitivity labels (Internal / Restricted)
- DLP policy (SSN pattern demo) to block external sharing
- Retention baseline policy + one exception

## Monitoring & automation
- Azure Automation Account (PowerShell 7) using Managed Identity
- Scheduled reporting runbooks (Graph) + report outputs
- Microsoft365DSC export + drift detection workflow

## Artifacts produced
- Reports: license, CA inventory, sign-in failures, secure score, etc.
- Runbooks + RCA templates
- Client packet (discovery, HLD, migration plan, comms, post-project report)
