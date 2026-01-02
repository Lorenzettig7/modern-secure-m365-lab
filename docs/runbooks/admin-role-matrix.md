# Admin Role Matrix (Least Privilege)

## Purpose
Document who has which Microsoft 365 admin roles in this lab tenant, and why.
Goal: least privilege + clear separation between **daily admin** and **break-glass**.

## Lab Identities
| Account | Purpose | Licensed? | Notes |
|---|---|---:|---|
| Admin-Gi | Daily admin | Yes | Used for normal admin work |
| BG1 | Break-glass | No | Emergency-only, excluded from Conditional Access |
| BG2 (optional) | Backup break-glass | No | Optional secondary break-glass |
| User1 | Standard user | Yes | Testing, device enrollment |
| User2 | Standard user | Yes | Testing, policy validation |

## Entra Groups (used for clean scoping)
| Group | Who’s in it | Used for |
|---|---|---|
| GG-Admins | Admin-Gi | Admin-scoped policies (CA, admin protections) |
| GG-Users-Standard | User1, User2 | Standard user policies |
| GG-CA-Exclusions-BreakGlass | BG1 (and BG2 if used) | Excluded from Conditional Access |

## Role Assignments (Entra ID Roles)
> Ideal in real orgs: daily admin is NOT global admin forever; use PIM + role-specific admins.
> For lab simplicity, document what you actually use.

| Role | Who has it | Why |
|---|---|---|
| Global Administrator | Admin-Gi | Day-to-day admin tasks (lab) |
| Global Administrator (break-glass) | BG1 | Emergency access if CA/MFA blocks admins |
| Global Reader (optional) | (fill in) | Read-only visibility if you want it |
| Intune Administrator | (fill in) | Device enrollment/config if separating duties |
| Exchange Administrator | (fill in) | Mail flow + security work |
| SharePoint Administrator | (fill in) | SharePoint/OneDrive governance |

## Break-glass Operating Rules
- BG accounts are **not used for daily admin**
- **Do not register MFA methods** on BG initially (avoid lockout loops)
- Keep password **stored offline** (password manager + backup)
- BG accounts are **excluded from Conditional Access**
- Every BG sign-in gets a short entry in: `m365-config/notes/day0-baseline.md`
  - date/time
  - reason
  - what was changed
  - confirmation it was logged

## (Optional) PIM Notes (if Entra P2 is available)
- Roles should be *eligible* and activated just-in-time
- Capture: activation request, approvals (if used), and audit logs
