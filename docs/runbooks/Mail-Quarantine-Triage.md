# Incident Runbook — Mail quarantined unexpectedly

## Symptoms
- User reports missing email; message appears in quarantine

## Scope check
- One sender/domain or multiple?
- Only certain users?

## Where to look
- Microsoft 365 Defender portal → Quarantine
- Exchange admin center → Mail flow rules

## Root cause patterns
- False positive in anti-phish/anti-spam
- Rule triggered unexpectedly
- DLP policy triggered (if scoped to Exchange)

## Fix
1. Find the quarantined message and reason
2. Release message (if safe)
3. Tune policy (allow list / adjust thresholds)
4. Monitor for repeat occurrences

## Prevention
- Regularly review quarantine trends
- Implement safe allow rules with guardrails
- Document exceptions and approvals
