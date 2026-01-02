# Conditional Access Policies (Lab Baseline)

## Overview
This tenant uses Conditional Access as the primary access control layer. Security Defaults were disabled to allow controlled CA deployment.

## Break-glass
- Account: bg1@Lorenzettig7.onmicrosoft.com
- Excluded via: GRP-CA-Exclude-BreakGlass
- MFA: intentionally not configured (emergency-only)

## Policies
| Policy | State | Scope | Key Controls | Notes |
|---|---|---|---|---|
| CA-01 Require MFA All Users | (On/Report-only) | All users (exclude break-glass) | Require MFA | Validated via sign-in logs |
| CA-02 Block Legacy Auth | On | All users (exclude break-glass) | Block legacy clients | Enforced early |
| CA-03 Require Compliant Device Admins | (On/Report-only) | Admin group | Require compliant device | Enabled after Intune compliance works |


