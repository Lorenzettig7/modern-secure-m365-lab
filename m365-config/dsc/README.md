# Microsoft365DSC (Tenant configuration as code)

## What this is
Microsoft365DSC is used here to **export a tenant baseline** ("golden snapshot") and to detect **configuration drift** by comparing a baseline export against a later export.

## Where exports live
- Baseline: `evidence/exports/baseline/`
- Current: `evidence/exports/current/`

## Prereqs (local workstation)
- PowerShell 7
- Microsoft365DSC module installed

## Baseline export (golden snapshot)
From repo root:

```powershell
pwsh
Export-M365DSCConfiguration -Components @(
  "AAD","Intune","EXO","SPO","Teams","Purview"
) -Path "./evidence/exports/baseline"
```

## Drift demo
1. Make a small intentional tenant change (ex: toggle one Intune setting)
2. Export again:

```powershell
Export-M365DSCConfiguration -Components @(
  "AAD","Intune","EXO","SPO","Teams","Purview"
) -Path "./evidence/exports/current"
```

3. Run your diff script:

```powershell
pwsh ./scripts/drift/Compare-M365DSC.ps1 -BaselinePath "./evidence/exports/baseline" -CurrentPath "./evidence/exports/current"
```

## Evidence to capture
- Screenshot of baseline export folder
- Screenshot of current export folder
- Screenshot of diff output proving drift
