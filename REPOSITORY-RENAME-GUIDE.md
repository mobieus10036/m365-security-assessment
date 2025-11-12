# Repository Rename Guide: M365Assessment → m365-security-guardian

This guide provides complete instructions for renaming the repository on GitHub and updating your local workspace.

## ✅ Changes Already Made

The following files have been updated with the new repository name:

### Core Files
- ✅ `README.md` - Repository URLs and report filenames
- ✅ `CONTRIBUTING.md` - Clone instructions
- ✅ `UPDATE_SUMMARY.md` - Repository references

### PowerShell Scripts
- ✅ `Start-M365Assessment.ps1` - Repository URL and report filename prefix
- ✅ `Enable-MailboxAuditing.ps1` - Repository URL and example paths
- ✅ `Install-Prerequisites.ps1` - Repository URL

### Module Files
- ✅ All 11 module files in `modules/Security/`, `modules/Exchange/`, `modules/Compliance/`, and `modules/Licensing/`

### Report Filename Changes
- Old: `M365Assessment_YYYYMMDD_HHMMSS.*`
- New: `M365Guardian_YYYYMMDD_HHMMSS.*`

---

## 🔄 GitHub Repository Rename Steps

### Step 1: Rename on GitHub

1. **Navigate to your repository** on GitHub:
   ```
   https://github.com/mobieus10036/M365Assessment
   ```

2. **Go to Settings**:
   - Click the "Settings" tab (you must be the repository owner)

3. **Rename the repository**:
   - Scroll down to the "Repository name" section
   - Change `M365Assessment` to `m365-security-guardian`
   - Click "Rename"

4. **GitHub will automatically**:
   - ✅ Set up redirects from the old URL
   - ✅ Update GitHub Pages (if configured)
   - ✅ Update issue/PR links

### Step 2: Update Your Local Repository

After renaming on GitHub, update your local git configuration:

```powershell
# Navigate to your local repository
cd E:\Dev\M365Assessment

# Update the remote URL
git remote set-url origin https://github.com/mobieus10036/m365-security-guardian.git

# Verify the change
git remote -v

# Pull latest changes (should include the updates made in this session)
git pull origin main
```

### Step 3: Rename Your Local Folder (Optional but Recommended)

```powershell
# Navigate to parent directory
cd E:\Dev

# Rename the local folder to match
Rename-Item -Path "M365Assessment" -NewName "m365-security-guardian"

# Navigate into the renamed folder
cd m365-security-guardian

# Verify everything still works
git status
```

---

## 📝 Important Notes

### GitHub Redirects
- GitHub automatically redirects `M365Assessment` → `m365-security-guardian`
- Old URLs will continue to work indefinitely
- Recommended to update bookmarks and documentation

### Report Files
- **New assessments** will use the new filename format: `M365Guardian_*`
- **Existing reports** in the `reports/` folder keep their old names
- No action needed for existing CSV/JSON/HTML files

### Breaking Changes
- None! The code changes are backward compatible
- Existing reports can still be read by remediation scripts

---

## 🔍 Verification Checklist

After renaming, verify everything works:

```powershell
# 1. Check git remote
git remote -v
# Should show: https://github.com/mobieus10036/m365-security-guardian.git

# 2. Test the assessment script
.\Start-M365Assessment.ps1 -WhatIf

# 3. Check generated report names
# Should create files like: M365Guardian_20251112_*.html

# 4. Verify GitHub links in help
Get-Help .\Start-M365Assessment.ps1 -Full
# Should reference m365-security-guardian
```

---

## 🌐 Update External References

### Update These Locations (if applicable):

1. **Bookmarks/Favorites**
   - Update browser bookmarks
   - Update documentation links

2. **CI/CD Pipelines**
   - Update GitHub Actions workflows
   - Update any scheduled tasks or automation

3. **Documentation Sites**
   - Update any external wiki/docs
   - Update team documentation

4. **Shared Links**
   - Notify team members of the new URL
   - Update any shared OneDrive/SharePoint links

---

## 🎯 Repository Naming Standard for Future Projects

Apply this standard to all future repositories:

### Format Pattern:
```
{platform}-{primary-function}-{type}
```

### Examples:
- `m365-security-guardian` - Current project
- `azure-cost-analyzer` - Azure cost analysis tool
- `powershell-exchange-automation` - Exchange automation module
- `azure-resource-monitor` - Azure monitoring tool

### Rules:
1. ✅ Use lowercase with hyphens (kebab-case)
2. ✅ Start with platform/technology (e.g., `azure-`, `m365-`, `powershell-`)
3. ✅ Include primary function (e.g., `security`, `monitoring`, `deployment`)
4. ✅ End with type descriptor (e.g., `-tool`, `-framework`, `-module`, `-guardian`)
5. ✅ Keep concise (2-4 words, max 50 characters)
6. ✅ Make it descriptive and discoverable

---

## 🚀 Next Steps

1. ✅ Rename repository on GitHub (Settings → Repository name)
2. ✅ Update local git remote URL
3. ✅ Rename local folder (optional)
4. ✅ Commit and push the code changes made in this session:
   ```powershell
   git add .
   git commit -m "Rename repository to m365-security-guardian and update all references"
   git push origin main
   ```
5. ✅ Test the assessment script to verify everything works
6. ✅ Update any external documentation or links

---

## 📞 Support

If you encounter any issues during the rename:
- **Old URL redirects**: GitHub handles these automatically
- **Local git issues**: Use `git remote set-url origin <new-url>`
- **Report files**: Old reports remain functional with old names

---

**Made with ❤️ and GitHub Copilot**
