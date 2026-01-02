# Incident Runbook — Conditional Access blocks sign-in

## Symptoms
- User receives a policy block message or cannot complete sign-in

## Scope check
- One user vs many users
- Confirm break-glass account still works

## Where to look
- Entra admin center → **Sign-in logs** (open the failed sign-in)
- Entra admin center → **Conditional Access** → Policy list

## Root cause patterns
- User/group scoping error (wrong include/exclude)
- Conditions too broad (client apps, locations, devices)
- MFA requirement conflicts with auth methods

## Fix
1. Identify which CA policy applied in the sign-in log
2. Set the policy to **Report-only** or adjust scope (temporary)
3. Re-test sign-in
4. Re-enable with corrected scope

## Prevention
- Always stage CA in **Report-only** first
- Keep break-glass excluded and tested
- Document intent and scope per policy
