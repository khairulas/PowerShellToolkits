<#
.SYNOPSIS
    Stops and disables the Windows Search (File Indexer) service.
.NOTES
    Requires Administrator privileges.
#>

# FIX: previously this relied on the try/catch below to reactively report
# "please run as Administrator" only after Stop-Service/Set-Service already
# failed. Checking up front is clearer and matches PremiumOptimizer.ps1's
# behavior for consistency across the toolkit.
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as an Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'." -ForegroundColor Yellow
    Exit
}

$ServiceName = "WSearch"

try {
    Write-Host "Checking the status of the Windows Search service..." -ForegroundColor Cyan

    # Check if the service is currently running and stop it
    if ((Get-Service -Name $ServiceName).Status -eq 'Running') {
        Write-Host "Stopping Windows Search service..." -ForegroundColor Yellow
        Stop-Service -Name $ServiceName -Force
    }

    # Change the startup type to Disabled
    Write-Host "Disabling Windows Search service startup..." -ForegroundColor Yellow
    Set-Service -Name $ServiceName -StartupType Disabled

    Write-Host "Success: Windows Search (File Indexer) has been completely disabled." -ForegroundColor Green
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
