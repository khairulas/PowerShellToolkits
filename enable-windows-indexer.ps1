<#
.SYNOPSIS
    Enables and starts the Windows Search (File Indexer) service.
.NOTES
    Requires Administrator privileges.
#>

# FIX: checking up front rather than only reacting to the error in catch -
# consistent with PremiumOptimizer.ps1 and disable-windows-indexer.ps1.
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as an Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'." -ForegroundColor Yellow
    Exit
}

$ServiceName = "WSearch"

try {
    # Change the startup type back to Automatic (Delayed Start is the Windows default, but Automatic works fine)
    Write-Host "Re-enabling Windows Search service startup..." -ForegroundColor Yellow
    Set-Service -Name $ServiceName -StartupType Automatic

    # Start the service
    Write-Host "Starting Windows Search service..." -ForegroundColor Yellow
    Start-Service -Name $ServiceName

    Write-Host "Success: Windows Search (File Indexer) has been re-enabled and is running." -ForegroundColor Green
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
