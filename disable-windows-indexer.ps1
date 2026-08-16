<#
.SYNOPSIS
Stops and disables the Windows Search (File Indexer) service.
#>

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
    Write-Host "Important: Please ensure you are running PowerShell as an Administrator." -ForegroundColor Red
}