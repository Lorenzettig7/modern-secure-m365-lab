# Email Authentication Plan (SPF / DKIM / DMARC)

## Current lab state
- Tenant uses the default `*.onmicrosoft.com` domain.
- With `onmicrosoft.com`, we do not manage DNS records for a custom domain.
- DKIM customization is typically done for **custom domains** (not the default `onmicrosoft.com` domain).

This document defines the production plan for enabling SPF/DKIM/DMARC once a custom domain is added.

---

## Goal
Prevent spoofing and improve deliverability by implementing:
- SPF (sender authorization)
- DKIM (message signing)
- DMARC (policy + reporting)

Rollout is staged to reduce risk:
1) SPF first
2) DKIM next
3) DMARC in monitor mode (p=none)
4) DMARC enforcement (quarantine → reject)

---

## SPF (Sender Policy Framework)

### What we will publish (typical for Exchange Online)
**TXT record** at root of domain (`@`):

`v=spf1 include:spf.protection.outlook.com -all`

### Notes
- If we add third-party senders (Mailchimp, SendGrid, etc.), we will add their SPF includes **carefully** to avoid exceeding SPF DNS lookup limits.
- We will validate with message header checks and an SPF checker after publishing.

---

## DKIM (DomainKeys Identified Mail)

### What we will do
1. In Microsoft 365 Defender or Exchange admin center, enable DKIM for the custom domain.
2. Microsoft will provide two selector CNAME records (selector1 and selector2).
3. Add the provided CNAME records in DNS.
4. Turn DKIM to **Enabled** and validate mail headers show `dkim=pass`.

### DNS records (example format only — actual targets come from the portal)
- `selector1._domainkey.<yourdomain>`  CNAME  →  `selector1-<yourdomain>-<tenant>._domainkey.<tenant>.onmicrosoft.com`
- `selector2._domainkey.<yourdomain>`  CNAME  →  `selector2-<yourdomain>-<tenant>._domainkey.<tenant>.onmicrosoft.com`

---

## DMARC (Domain-based Message Authentication, Reporting & Conformance)

### Stage 1: Monitor only (recommended)
**TXT record** at `_dmarc.<yourdomain>`:

`v=DMARC1; p=none; rua=mailto:dmarc-reports@<yourdomain>; adkim=s; aspf=s; pct=100`

### Stage 2: Quarantine
After reports look clean:

`v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@<yourdomain>; adkim=s; aspf=s; pct=100`

### Stage 3: Reject
Final enforcement:

`v=DMARC1; p=reject; rua=mailto:dmarc-reports@<yourdomain>; adkim=s; aspf=s; pct=100`

### Notes
- `rua` is an aggregate report mailbox (can be a shared mailbox or a third-party DMARC reporting service).
- We will verify alignment (From domain aligns with SPF and/or DKIM).

---

## Validation checklist (once custom domain is live)
- SPF: headers show `spf=pass`
- DKIM: headers show `dkim=pass`
- DMARC: headers show `dmarc=pass`
- DMARC reports received at `rua` mailbox
- No legitimate services are failing alignment

---

## References
- Microsoft 365 / Exchange Online documentation for SPF, DKIM, DMARC configuration (follow portal-provided values for selectors and DNS).
