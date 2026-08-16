<#
.SYNOPSIS
    Clears user and system temporary files to free up disk space.
.DESCRIPTION
    Fast purge of $env:TEMP and (if run as Administrator) $env:WINDIR\Temp.
    Reports how much space was actually freed rather than assuming success -
    deleting files under $env:WINDIR\Temp normally requires Administrator
    rights, so on a standard user session most of that folder is skipped
    rather than silently failing while still claiming "Success".
#>

function Clear-TempFolder {
    param([string]$Path)

    $freed = 0
    $skipped = 0

    if (-not (Test-Path $Path)) { return @{ Freed = 0; Skipped = 0 } }

    $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue
    foreach ($item in $items) {
        try {
            # FIX: piping an EMPTY result straight into Measure-Object
            # -Property Length throws "property cannot be found" under
            # Windows PowerShell 5.1 for an empty subfolder (PS7 handles it
            # silently). Check for content first instead of piping directly.
            $size = if ($item.PSIsContainer) {
                $subItems = Get-ChildItem -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                if ($subItems) { ($subItems | Measure-Object -Property Length -Sum).Sum } else { 0 }
            } else {
                $item.Length
            }
            if (-not $size) { $size = 0 }
            Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
            $freed += $size
        } catch {
            $skipped++
        }
    }

    return @{ Freed = $freed; Skipped = $skipped }
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "Clearing User Temp folder..." -ForegroundColor Yellow
$userResult = Clear-TempFolder -Path "$env:TEMP"

if (-not $isAdmin) {
    # FIX: previously the script attempted WINDIR\Temp regardless and just
    # printed "Success" no matter what actually happened. Most files there
    # need elevation, so without admin this is now explicit rather than a
    # silent no-op dressed up as a success message.
    Write-Host "Not running as Administrator - skipping Windows Temp folder (most files there need elevation)." -ForegroundColor Yellow
    $winResult = @{ Freed = 0; Skipped = 0 }
} else {
    Write-Host "Clearing Windows Temp folder..." -ForegroundColor Yellow
    $winResult = Clear-TempFolder -Path "$env:WINDIR\Temp"
}

$totalFreedMB = [math]::Round((($userResult.Freed + $winResult.Freed) / 1MB), 2)
$totalSkipped = $userResult.Skipped + $winResult.Skipped

Write-Host "Done: freed $totalFreedMB MB. $totalSkipped item(s) were locked/in use and skipped." -ForegroundColor Green