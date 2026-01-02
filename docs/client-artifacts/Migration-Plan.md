# Migration Plan (Template)

> Use this even if you don’t execute a real migration in the lab — it shows you know how to deliver.

## Migration approach
- Exchange: cutover vs staged vs hybrid (pick one and justify)
- Identity: cloud-only vs hybrid, MFA rollout, CA transition
- Endpoint: enrollment plan (pilot → broad)

## Cutover steps
1. Pre-change validation
2. Identity controls in report-only → enforce
3. Endpoint enrollment pilot
4. Email security baseline deployment
5. Teams/SharePoint governance changes
6. Purview labels/DLP rollout
7. Post-change verification

## Rollback plan
- How to revert CA policies safely (use break-glass)
- How to revert mail flow rules
- How to roll back Intune policies

## Communication plan
- Use templates in `docs/comms-templates/`

## Post-migration validation checklist
- Users can sign in (MFA works, CA behaves)
- Admin access works (compliant device path)
- Mail flow + quarantine functions
- Teams/SharePoint access + sharing behaves as intended
- DLP triggers on test content
- Automation runbooks run successfully and generate reports
