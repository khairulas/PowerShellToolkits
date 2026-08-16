<#
.SYNOPSIS
Enables and starts the Windows Search (File Indexer) service.
#>

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
    Write-Host "Important: Please ensure you are running PowerShell as an Administrator." -ForegroundColor Red
}