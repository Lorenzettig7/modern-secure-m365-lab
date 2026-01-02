# Incident Runbook — Azure Automation runbook failure

## Symptoms
- Runbook job status = Failed
- Missing expected report output

## Scope check
- One runbook or all runbooks failing?
- Was there a recent permissions or module change?

## Where to look
- Azure portal → Automation Account → Runbooks → Job history → Job output + errors
- Entra admin center → Enterprise apps → Automation account → Permissions

## Root cause patterns
- Missing Graph app role assignment for managed identity
- Graph throttling/transient errors
- Script error (null value, bad filter, output path issue)

## Fix
1. Open job errors; copy the exact error message
2. If permission-related: assign missing Graph role and re-run
3. If transient: retry; add backoff logic
4. Fix script and re-publish runbook

## Prevention
- Add lightweight retry + clearer error output
- Add alerting/notification for failed jobs
- Keep scripts in Git as source of truth; avoid portal-only edits
