# Quick Reference: DNS Email Authentication Validation

## What Gets Checked

| Protocol | Check Method | What's Validated |
|----------|--------------|------------------|
| **SPF** | DNS TXT lookup on domain | ✅ Record exists<br>✅ Contains Microsoft servers |
| **DKIM** | Exchange Online API | ✅ Enabled in Exchange<br>✅ Per-domain status |
| **DMARC** | DNS TXT lookup on `_dmarc.domain` | ✅ Record exists<br>✅ Policy strength (none/quarantine/reject) |

## Status Meanings

### SPF Status
- ✅ **Valid**: SPF record found with Microsoft included
- ⚠️ **Invalid (Missing Microsoft)**: SPF exists but doesn't authorize Microsoft 365
- ❌ **Missing**: No SPF record found
- ❓ **DNS Lookup Failed**: Unable to query DNS

### DKIM Status
- ✅ **Enabled**: DKIM signing is enabled in Exchange Online
- ❌ **Disabled**: DKIM signing is not enabled
- ❓ **Check Failed**: Unable to query Exchange Online

### DMARC Status
- ✅ **Valid (Policy: reject)**: Strong enforcement - reject unauthorized emails
- ✅ **Valid (Policy: quarantine)**: Moderate enforcement - quarantine suspicious emails
- ⚠️ **Weak (Policy: none)**: Monitoring only - no enforcement
- ❌ **Missing**: No DMARC record found
- ❓ **DNS Lookup Failed**: Unable to query DNS

## Common Issues & Fixes

### Issue: SPF Missing
**Problem**: No SPF record found for domain

**Fix**:
```dns
TXT record for domain: v=spf1 include:spf.protection.outlook.com -all
```

**Where to add**: Your domain's DNS provider (GoDaddy, Cloudflare, etc.)

### Issue: SPF Invalid (Missing Microsoft)
**Problem**: SPF exists but doesn't include Microsoft 365 servers

**Fix**: Update existing SPF record to include:
```dns
include:spf.protection.outlook.com
```

**Example**:
```dns
Before: v=spf1 include:_spf.google.com -all
After:  v=spf1 include:spf.protection.outlook.com include:_spf.google.com -all
```

### Issue: DKIM Disabled
**Problem**: DKIM not enabled in Exchange Online

**Fix**:
1. Go to [Exchange Admin Center](https://admin.exchange.microsoft.com)
2. Navigate to **Protection** → **DKIM**
3. Select your domain
4. Click **Enable**
5. Copy the two CNAME records shown
6. Add them to your DNS:
   - `selector1._domainkey` → CNAME to Microsoft
   - `selector2._domainkey` → CNAME to Microsoft

### Issue: DMARC Missing
**Problem**: No DMARC record found

**Fix**: Add TXT record to DNS:
```dns
Host/Name: _dmarc
Type: TXT
Value: v=DMARC1; p=none; rua=mailto:dmarc-reports@yourdomain.com
```

**Gradual Enforcement**:
1. **Week 1-4**: `p=none` (monitoring only, collect reports)
2. **Week 5-8**: `p=quarantine; pct=10` (quarantine 10% of failures)
3. **Week 9-12**: `p=quarantine; pct=100` (quarantine all failures)
4. **Week 13+**: `p=reject` (reject all failures)

### Issue: DMARC Weak Policy
**Problem**: DMARC set to `p=none` (no enforcement)

**Fix**: Gradually strengthen policy after monitoring:
```dns
Step 1: p=none         → Monitor for 2-4 weeks
Step 2: p=quarantine   → Test enforcement for 2-4 weeks  
Step 3: p=reject       → Full protection
```

## DNS Record Examples

### Complete Setup for `contoso.com`

#### SPF Record
```dns
Type: TXT
Host: @  (or contoso.com)
Value: v=spf1 include:spf.protection.outlook.com -all
TTL: 3600
```

#### DKIM CNAMEs (provided by Microsoft)
```dns
Type: CNAME
Host: selector1._domainkey
Value: selector1-contoso-com._domainkey.contoso.onmicrosoft.com
TTL: 3600

Type: CNAME
Host: selector2._domainkey
Value: selector2-contoso-com._domainkey.contoso.onmicrosoft.com
TTL: 3600
```

#### DMARC Record
```dns
Type: TXT
Host: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:dmarc@contoso.com; ruf=mailto:dmarc@contoso.com; pct=100
TTL: 3600
```

## Testing Your Configuration

### Manual DNS Testing
```powershell
# Test SPF
Resolve-DnsName -Name contoso.com -Type TXT | Where-Object { $_.Strings -like "v=spf1*" }

# Test DKIM (check if CNAMEs exist)
Resolve-DnsName -Name selector1._domainkey.contoso.com -Type CNAME
Resolve-DnsName -Name selector2._domainkey.contoso.com -Type CNAME

# Test DMARC
Resolve-DnsName -Name _dmarc.contoso.com -Type TXT | Where-Object { $_.Strings -like "v=DMARC1*" }
```

### Online Tools
- [MXToolbox SPF Check](https://mxtoolbox.com/spf.aspx)
- [MXToolbox DKIM Check](https://mxtoolbox.com/dkim.aspx)
- [MXToolbox DMARC Check](https://mxtoolbox.com/dmarc.aspx)
- [Microsoft DMARC Analyzer](https://aka.ms/dmarc)

## Assessment Report Locations

After running the assessment, find details in:

### HTML Report
- Main summary with pass/fail counts
- Detailed domain table with visual indicators
- Recommendations section

### CSV Export
- `M365Assessment_YYYYMMDD_HHMMSS.csv` - Main results
- `M365Assessment_YYYYMMDD_HHMMSS_DomainEmailAuth.csv` - Per-domain DNS details

### JSON Export
- `M365Assessment_YYYYMMDD_HHMMSS.json` - Complete data with nested domain details

## Best Practices

1. **Always start with SPF** - It's the foundation
2. **Enable DKIM for all domains** - Adds cryptographic signing
3. **Deploy DMARC gradually** - Start with monitoring (`p=none`)
4. **Monitor DMARC reports** - Identify legitimate vs. illegitimate sources
5. **Use subdomains wisely** - Apply stricter policies to non-sending domains
6. **Keep records updated** - Remove old includes when migrating services

## Common DNS Provider Instructions

### GoDaddy
1. Log in to GoDaddy Domain Manager
2. Click **DNS** → **Manage Zones**
3. Click **Add** → Select record type (TXT or CNAME)
4. Enter host, value, and save

### Cloudflare
1. Log in to Cloudflare dashboard
2. Select your domain
3. Go to **DNS** → **Records**
4. Click **Add record**
5. Select type, enter name and content

### Microsoft DNS (Azure DNS)
1. Go to Azure Portal
2. Navigate to **DNS zones**
3. Select your zone
4. Click **+ Record set**
5. Enter name, type, and value

### Network Solutions
1. Log in to Account Manager
2. Click **Manage** next to domain
3. Click **Advanced DNS**
4. Add TXT or CNAME records

## Support & Documentation

- **Microsoft Learn**: https://learn.microsoft.com/defender-office-365/email-authentication-about
- **Assessment Toolkit Docs**: See `docs/` folder in repository
- **Issue Tracking**: GitHub repository issues

## DNS Propagation

**Important**: DNS changes take time to propagate
- **Typical**: 1-4 hours
- **Maximum**: 24-48 hours
- **TTL matters**: Lower TTL = faster updates (but more queries)

Check propagation: https://www.whatsmydns.net/

## Troubleshooting

### DNS Lookup Fails
- Check internet connectivity
- Verify DNS server is responding
- Try alternative DNS servers (8.8.8.8, 1.1.1.1)
- Check Windows Firewall isn't blocking DNS

### DKIM Won't Enable
- Ensure domain is verified in Microsoft 365
- Check that domain isn't a subdomain (use parent domain)
- Wait up to 72 hours after adding CNAME records

### DMARC Reports Not Received
- Check `rua=` email address is valid
- Verify no SPF/DKIM failures are occurring
- Some providers delay reports (daily batches)
- Ensure report mailbox isn't blocking/quarantining
