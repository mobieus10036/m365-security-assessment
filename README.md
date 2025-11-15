# M365 Security Guardian

PowerShell toolkit for security engineers, administrators, and auditors to baseline and review Microsoft 365 security posture. Runs read-only checks and exports results as HTML/CSV/JSON reports you can review or attach to an assessment.

## Quick Start

Prerequisites

- Windows PowerShell 5.1+ or PowerShell 7
- Microsoft 365 account with at least Global Reader
- Ability to install required PowerShell modules (handled by `Install-Prerequisites.ps1`)

Setup and run

```powershell
git clone https://github.com/mobieus10036/m365-security-guardian.git
cd m365-security-guardian
./Install-Prerequisites.ps1
./Start-M365Assessment.ps1
```
 
Reports are written to `reports/` (for example, `Security-Summary.html`, `Exchange-Details.csv`).

## What It Checks

- Security: MFA, Conditional Access, legacy auth, privileged accounts
- Exchange: anti-spam/malware, Safe Links/Attachments, SPF/DKIM/DMARC, mailbox auditing
- Licensing: assignments, inactive users, optimization signals

## Run Specific Modules

```powershell
# Security only
./Start-M365Assessment.ps1 -Modules Security

# Security + Exchange
./Start-M365Assessment.ps1 -Modules Security,Exchange

# All (default)
./Start-M365Assessment.ps1
```

Available: `Security`, `Exchange`, `Licensing`, `All`.

## Output Formats

- `HTML`: dashboards and human-readable summaries
- `CSV`: tabular data for spreadsheets or BI tools
- `JSON`: structured data for automation (if enabled in configuration)
- `All`: generates all available formats (default)

```powershell
./Start-M365Assessment.ps1 -OutputFormat HTML   # just HTML
./Start-M365Assessment.ps1 -OutputFormat CSV    # just CSVs
./Start-M365Assessment.ps1 -OutputFormat All    # default (HTML/CSV/JSON)
```

## Configuration (optional)

Edit `config/assessment-config.json` or pass a custom file:

```powershell
./Start-M365Assessment.ps1 -ConfigPath ./my-config.json
```

## Permissions

- Global Reader: most checks
- Security Reader / Compliance Administrator: some checks
- Global Administrator: full access (not required)

## Notes

- Read-only: scripts do not modify tenant settings.
- Reports may contain sensitive details; store and share carefully.

### Troubleshooting

- If scripts are blocked, use an elevated session or set an execution policy for the current process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

- If sign-in fails, verify the account has at least Global Reader and any additional roles needed for specific workloads (for example, Security Reader for security reports).

## Support

- Issues: [GitHub Issues](https://github.com/mobieus10036/m365-security-guardian/issues)
- Security: see `SECURITY.md`

## License

MIT — see `LICENSE`.

## Contributing

Keep Markdown succinct and emoji-free.

- Format and normalize:

```powershell
pwsh -File tools/Format-Markdown.ps1
```

- Optional: enable pre-commit hook:

```powershell
git config core.hooksPath .githooks
```

- Optional: lint locally:

```bash
npx -y markdownlint-cli2 "**/*.md"
```

Pull requests are linted in CI.
