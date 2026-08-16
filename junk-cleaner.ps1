<#
.SYNOPSIS
Clears user and system temporary files to free up disk space and improve I/O speed.
#>

try {
    Write-Host "Clearing User Temp folder..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Clearing Windows Temp folder..." -ForegroundColor Yellow
    Remove-Item -Path "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Success: Temporary files cleared." -ForegroundColor Green
}
catch {
    Write-Host "Finished with minor locked-file warnings. (This is normal for files currently in use)." -ForegroundColor Cyan
}