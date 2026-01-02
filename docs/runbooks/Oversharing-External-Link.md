# Incident Runbook — Oversharing / external link exposure

## Symptoms
- File/site shared externally beyond intended scope

## Scope check
- Single file vs entire site?
- Is the link anonymous or guest-authenticated?

## Where to look
- SharePoint admin center → Policies → Sharing
- Site-level sharing settings
- Audit logs for sharing events

## Root cause patterns
- Sharing settings too permissive (tenant or site)
- Users creating anonymous links

## Fix
1. Identify the item and link type
2. Revoke sharing link(s) and tighten permissions
3. Adjust tenant/site sharing settings as needed
4. Validate access is corrected

## Prevention
- Prefer guest-authenticated links over anonymous
- Periodic review of externally shared items
- Apply DLP where sensitive data may be shared
