# DNS Validation Architecture

## System Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Start-M365Assessment.ps1                          │
│                     (Main Orchestrator)                              │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ├─ Load Configuration
                             ├─ Connect to M365 Services
                             │
                             v
         ┌───────────────────────────────────────────────┐
         │    Exchange Module Assessment                 │
         │    Test-SPFDKIMDmarc.ps1                      │
         └───────────────────┬───────────────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          v                  v                  v
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │   SPF    │      │   DKIM   │      │  DMARC   │
    │ DNS TXT  │      │ Exchange │      │ DNS TXT  │
    │  Lookup  │      │   API    │      │  Lookup  │
    └────┬─────┘      └────┬─────┘      └────┬─────┘
         │                 │                  │
         │  Resolve-       │  Get-            │  Resolve-
         │  DnsName        │  DkimSigning     │  DnsName
         │  domain.com     │  Config          │  _dmarc.domain.com
         │  -Type TXT      │                  │  -Type TXT
         │                 │                  │
         └─────────────────┴──────────────────┘
                           │
                           v
                ┌──────────────────────┐
                │  Validation Logic    │
                │                      │
                │  • Check SPF exists  │
                │  • Validate MS inc.  │
                │  • Check DKIM on     │
                │  • Check DMARC pol.  │
                └──────────┬───────────┘
                           │
                           v
                ┌──────────────────────┐
                │  Result Object       │
                │                      │
                │  • Overall Status    │
                │  • Domain Details[]  │
                │  • Issues[]          │
                │  • Recommendations   │
                └──────────┬───────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          v                v                v
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │   HTML   │    │   CSV    │    │   JSON   │
    │  Report  │    │  Export  │    │  Export  │
    └──────────┘    └──────────┘    └──────────┘
         │                │                │
         │                ├─ Main CSV      │
         │                ├─ DomainAuth    │
         │                └─ NonCompliant  │
         │                                 │
         v                                 v
    Domain Table                     Full Details
    with Icons                       with Records
```

## DNS Validation Detail

```
For each Accepted Domain (excluding InternalRelay):
┌─────────────────────────────────────────────────────────────┐
│                      Domain: contoso.com                     │
└─────────────────────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        v                    v                    v
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  SPF Check    │    │  DKIM Check   │    │  DMARC Check  │
├───────────────┤    ├───────────────┤    ├───────────────┤
│               │    │               │    │               │
│ DNS Query:    │    │ API Call:     │    │ DNS Query:    │
│ contoso.com   │    │ Get-DkimSign  │    │ _dmarc.       │
│ TXT record    │    │ ingConfig     │    │ contoso.com   │
│               │    │               │    │ TXT record    │
├───────────────┤    ├───────────────┤    ├───────────────┤
│               │    │               │    │               │
│ Validate:     │    │ Check:        │    │ Validate:     │
│ • v=spf1      │    │ • Enabled?    │    │ • v=DMARC1    │
│ • include:    │    │ • Per domain  │    │ • Policy:     │
│   spf.protect │    │               │    │   - reject    │
│   ion.outlook │    │               │    │   - quarantine│
│   .com        │    │               │    │   - none      │
│               │    │               │    │               │
├───────────────┤    ├───────────────┤    ├───────────────┤
│               │    │               │    │               │
│ Result:       │    │ Result:       │    │ Result:       │
│ ✅ Valid      │    │ ✅ Enabled    │    │ ✅ Valid      │
│ ⚠️ Invalid   │    │ ❌ Disabled   │    │ ⚠️ Weak      │
│ ❌ Missing   │    │ ❓ Failed     │    │ ❌ Missing   │
│ ❓ Failed    │    │               │    │ ❓ Failed    │
└───────────────┘    └───────────────┘    └───────────────┘
        │                    │                    │
        └────────────────────┴────────────────────┘
                             │
                             v
                    ┌──────────────────┐
                    │  Domain Result   │
                    │                  │
                    │  Domain: ...     │
                    │  SPF: Valid      │
                    │  SPFRecord: ...  │
                    │  DKIM: Enabled   │
                    │  DMARC: Valid    │
                    │  DMARCRecord: ...│
                    │  DMARCPolicy: ...|
                    └──────────────────┘
```

## Status Determination Flow

```
┌─────────────────────────────────────────────────────────────┐
│               Aggregate Domain Results                       │
└─────────────────────────────────────────────────────────────┘
                             │
                             v
                    ┌──────────────────┐
                    │  Calculate Stats │
                    ├──────────────────┤
                    │ SPF Valid: X/Y   │
                    │ DKIM Enabled: X/Y│
                    │ DMARC Valid: X/Y │
                    └────────┬─────────┘
                             │
                             v
                    ┌──────────────────┐
                    │  Determine       │
                    │  Overall Status  │
                    └────────┬─────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          v                  v                  v
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │   FAIL   │      │ WARNING  │      │   PASS   │
    ├──────────┤      ├──────────┤      ├──────────┤
    │          │      │          │      │          │
    │ Any of:  │      │ Some:    │      │ All:     │
    │ • No SPF │      │ • Invalid│      │ • SPF OK │
    │ • No DMARC│     │   SPF    │      │ • DKIM OK│
    │ • No DKIM│      │ • Weak   │      │ • DMARC  │
    │          │      │   DMARC  │      │   Strong │
    │          │      │ • Partial│      │          │
    │ Severity:│      │   DKIM   │      │ Severity:│
    │   HIGH   │      │ Severity:│      │   LOW    │
    │          │      │  MEDIUM  │      │          │
    └──────────┘      └──────────┘      └──────────┘
```

## Report Output Structure

```
M365Assessment_20251109_093614/
│
├─ .html
│  └─ Contains:
│     • Summary cards (Pass/Fail counts)
│     • Results table
│     • Domain table (embedded)
│       ┌────────────────────────────────────────┐
│       │ Domain        │ SPF │ DKIM │ DMARC    │
│       ├────────────────────────────────────────┤
│       │ contoso.com   │ ✅  │ ✅   │ ✅       │
│       │ fabrikam.com  │ ⚠️  │ ❌   │ ❌       │
│       └────────────────────────────────────────┘
│
├─ .json
│  └─ Contains:
│     • Full assessment results
│     • DomainDetails array
│       {
│         "Domain": "contoso.com",
│         "SPF": "Valid",
│         "SPFRecord": "v=spf1 include:...",
│         "DKIM": "Enabled",
│         "DMARC": "Valid (Policy: reject)",
│         "DMARCRecord": "v=DMARC1; p=reject...",
│         "DMARCPolicy": "reject"
│       }
│
├─ .csv (main)
│  └─ Summary results per check
│
└─ _DomainEmailAuth.csv
   └─ Per-domain DNS details
      Domain,SPF,SPFRecord,DKIM,DMARC,DMARCRecord,DMARCPolicy
      contoso.com,Valid,"v=spf1 include:...",Enabled,"Valid (Policy: reject)","v=DMARC1; p=reject...",reject
```

## Data Flow Example

```
Input: Accepted Domains from Exchange Online
┌─────────────────────────────────────────┐
│ contoso.com                             │
│ fabrikam.com                            │
│ tailspintoys.com                        │
└─────────────────────────────────────────┘
                  │
                  v
DNS Lookups Performed (6 queries)
┌─────────────────────────────────────────┐
│ 1. contoso.com TXT (SPF)                │
│ 2. _dmarc.contoso.com TXT (DMARC)       │
│ 3. fabrikam.com TXT (SPF)               │
│ 4. _dmarc.fabrikam.com TXT (DMARC)      │
│ 5. tailspintoys.com TXT (SPF)           │
│ 6. _dmarc.tailspintoys.com TXT (DMARC)  │
└─────────────────────────────────────────┘
                  │
                  v
Exchange Online API Calls (3 queries)
┌─────────────────────────────────────────┐
│ Get-DkimSigningConfig -Identity         │
│   contoso.com                           │
│ Get-DkimSigningConfig -Identity         │
│   fabrikam.com                          │
│ Get-DkimSigningConfig -Identity         │
│   tailspintoys.com                      │
└─────────────────────────────────────────┘
                  │
                  v
Validation & Analysis
┌─────────────────────────────────────────┐
│ contoso.com:                            │
│   SPF: ✅ Valid (MS included)          │
│   DKIM: ✅ Enabled                     │
│   DMARC: ✅ Valid (p=reject)           │
│                                         │
│ fabrikam.com:                           │
│   SPF: ⚠️ Invalid (No MS)              │
│   DKIM: ❌ Disabled                    │
│   DMARC: ❌ Missing                    │
│                                         │
│ tailspintoys.com:                       │
│   SPF: ✅ Valid                        │
│   DKIM: ✅ Enabled                     │
│   DMARC: ⚠️ Weak (p=none)              │
└─────────────────────────────────────────┘
                  │
                  v
Overall Status: WARNING (Medium Severity)
┌─────────────────────────────────────────┐
│ SPF Valid: 2/3 (66.7%)                  │
│ DKIM Enabled: 2/3 (66.7%)               │
│ DMARC Enforced: 1/3 (33.3%)             │
│                                         │
│ Issues:                                 │
│ • fabrikam.com - SPF invalid            │
│ • fabrikam.com - DKIM disabled          │
│ • fabrikam.com - DMARC missing          │
│ • tailspintoys.com - DMARC weak         │
└─────────────────────────────────────────┘
```

## Component Dependencies

```
┌────────────────────────────────────────────┐
│    Windows PowerShell 5.1+ / PS 7+        │
└────────────────────┬───────────────────────┘
                     │
     ┌───────────────┼───────────────┐
     │               │               │
     v               v               v
┌─────────┐   ┌─────────┐   ┌─────────┐
│ Resolve-│   │Exchange │   │ Internet│
│ DnsName │   │ Online  │   │  DNS    │
│ Cmdlet  │   │   PS    │   │ Servers │
└─────────┘   └─────────┘   └─────────┘
     │               │               │
     └───────────────┴───────────────┘
                     │
                     v
        ┌────────────────────────┐
        │   Test-SPFDKIMDmarc    │
        │      Module v2.0       │
        └────────────────────────┘
```
