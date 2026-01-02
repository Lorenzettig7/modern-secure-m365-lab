# Incident Runbook — Noncompliant device blocks access

## Symptoms
- User blocked with “device must be compliant” style message

## Scope check
- Is it one device or all devices?
- Are only admins affected?

## Where to look
- Intune admin center → Devices → All devices → device compliance status
- Entra admin center → Sign-in logs → confirm CA policy requiring compliance

## Root cause patterns
- Device not enrolled or enrollment broken
- Compliance policy failing (encryption, password, OS version)

## Fix
1. Confirm device is enrolled and shows up as managed
2. Check the device compliance policy and failure reason
3. Remediate on device (enable BitLocker, set password/PIN, update OS)
4. Sync device; re-check compliance

## Prevention
- Pilot compliance changes before enforcing
- Communicate requirements to users
- Use targeted scoping for high-risk users first
