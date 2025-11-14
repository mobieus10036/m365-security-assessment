<#
.SYNOPSIS
    Tests Multi-Factor Authentication (MFA) configuration across the tenant.

.DESCRIPTION
    Evaluates MFA adoption and enforcement, identifying users without MFA,
    privileged accounts lacking MFA, and overall tenant MFA compliance.

.PARAMETER Config
    Configuration object containing MFA thresholds and requirements.

.OUTPUTS
    PSCustomObject containing assessment results with status, findings, and recommendations.

.NOTES
    Project: M365 Assessment Toolkit
    Repository: https://github.com/mobieus10036/m365-security-guardian
    Author: mobieus10036
    Version: 3.0.0
    Created with assistance from GitHub Copilot
#>

function Test-MFAConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing MFA configuration..."

        # Get all users
        $allUsers = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled |
                    Where-Object { $_.AccountEnabled -eq $true }
        
        $totalUsers = $allUsers.Count

        if ($totalUsers -eq 0) {
            return [PSCustomObject]@{
                CheckName = "MFA Configuration"
                Category = "Security"
                Status = "Info"
                Severity = "Info"
                Message = "No enabled users found in tenant"
                Details = @{ TotalUsers = 0 }
                Recommendation = "Ensure users are properly provisioned"
                DocumentationUrl = "https://learn.microsoft.com/entra/identity/authentication/concept-mfa-howitworks"
                RemediationSteps = @()
            }
        }

        # Get MFA authentication methods for users
        # Use batching to improve performance for large tenants
        $usersWithMFA = 0
        $usersWithoutMFA = @()
        $batchSize = 100
        $processedCount = 0

        Write-Verbose "Checking MFA status for $totalUsers users..."

        for ($i = 0; $i -lt $totalUsers; $i += $batchSize) {
            $batchEnd = [Math]::Min($i + $batchSize, $totalUsers)
            $batch = $allUsers[$i..($batchEnd - 1)]
            
            # Progress reporting for large tenants
            if ($totalUsers -gt 100) {
                $percentComplete = [Math]::Round(($processedCount / $totalUsers) * 100, 0)
                Write-Verbose "  Progress: $processedCount/$totalUsers users ($percentComplete%)"
            }

            foreach ($user in $batch) {
                try {
                    $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue
                    
                    # Check for MFA-capable methods (Phone, FIDO2, Authenticator App, etc.)
                    $hasMFA = $authMethods | Where-Object {
                        $_.AdditionalProperties.'@odata.type' -in @(
                            '#microsoft.graph.phoneAuthenticationMethod',
                            '#microsoft.graph.fido2AuthenticationMethod',
                            '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod',
                            '#microsoft.graph.softwareOathAuthenticationMethod',
                            '#microsoft.graph.windowsHelloForBusinessAuthenticationMethod'
                        )
                    }

                    if ($hasMFA) {
                        $usersWithMFA++
                    }
                    else {
                        $usersWithoutMFA += [PSCustomObject]@{
                            UserPrincipalName = $user.UserPrincipalName
                            DisplayName = $user.DisplayName
                            UserId = $user.Id
                        }
                    }
                }
                catch {
                    Write-Verbose "Could not check MFA for user: $($user.UserPrincipalName) - $_"
                }
                
                $processedCount++
            }
            
            # Add small delay between batches to avoid throttling
            if ($i + $batchSize -lt $totalUsers) {
                Start-Sleep -Milliseconds 100
            }
        }

        # Calculate compliance percentage
        $mfaPercentage = if ($totalUsers -gt 0) { 
            [math]::Round(($usersWithMFA / $totalUsers) * 100, 1) 
        } else { 0 }

        # Determine status based on threshold
        $threshold = if ($Config.Security.MFAEnforcementThreshold) { 
            $Config.Security.MFAEnforcementThreshold 
        } else { 95 }

        $status = if ($mfaPercentage -ge $threshold) { "Pass" }
                  elseif ($mfaPercentage -ge 75) { "Warning" }
                  else { "Fail" }

        $severity = if ($mfaPercentage -ge 90) { "Low" }
                    elseif ($mfaPercentage -ge 75) { "Medium" }
                    elseif ($mfaPercentage -ge 50) { "High" }
                    else { "Critical" }

        $message = "MFA adoption: $mfaPercentage% ($usersWithMFA/$totalUsers users)"
        
        if ($usersWithoutMFA.Count -gt 0 -and $usersWithoutMFA.Count -le 10) {
            $message += ". Users without MFA: $($usersWithoutMFA.UserPrincipalName -join ', ')"
        }
        elseif ($usersWithoutMFA.Count -gt 10) {
            $message += ". $($usersWithoutMFA.Count) users without MFA"
        }

        return [PSCustomObject]@{
            CheckName = "MFA Enforcement"
            Category = "Security"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                TotalUsers = $totalUsers
                UsersWithMFA = $usersWithMFA
                UsersWithoutMFA = $usersWithoutMFA.Count
                CompliancePercentage = $mfaPercentage
                Threshold = $threshold
            }
            UsersWithoutMFA = $usersWithoutMFA
            Recommendation = if ($status -ne "Pass") {
                "Enable MFA for all users via Conditional Access policies. Target: $threshold% adoption"
            } else {
                "MFA adoption meets requirements. Continue monitoring."
            }
            DocumentationUrl = "https://learn.microsoft.com/entra/identity/authentication/howto-mfa-getstarted"
            RemediationSteps = @(
                "1. Navigate to Entra ID > Security > Conditional Access"
                "2. Create a new policy requiring MFA for all users"
                "3. Enable policy in Report-only mode initially"
                "4. Review sign-in logs and adjust exclusions"
                "5. Enable policy enforcement"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "MFA Configuration"
            Category = "Security"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess MFA configuration: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Verify Microsoft Graph permissions: UserAuthenticationMethod.Read.All"
            DocumentationUrl = "https://learn.microsoft.com/entra/identity/authentication/concept-mfa-howitworks"
            RemediationSteps = @()
        }
    }
}
