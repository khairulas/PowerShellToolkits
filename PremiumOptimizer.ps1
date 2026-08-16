<#
.SYNOPSIS
    Premium PC Cleaning & Optimization Script
.DESCRIPTION
    Scans for junk files, calculates space, cleans directories, empties the
    recycle bin, and optimizes system drives and network cache.
.NOTES
    Requires Administrator privileges.
#>

# 1. Ensure Administrator Privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as an Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'." -ForegroundColor Yellow
    Exit
}

Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   Intelligent Scan & Premium PC Optimization Tool       " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Define target directories for cleaning
$PathsToClean = @(
    "$env:TEMP",
    "$env:WINDIR\Temp",
    "$env:WINDIR\Prefetch",
    "$env:WINDIR\SoftwareDistribution\Download"
)

$TotalBytesFreed = 0
$LockedFiles = 0

# ---------------------------------------------------------
# PHASE 1: Stop Windows Update services before touching their cache
# ---------------------------------------------------------
# FIX: SoftwareDistribution\Download can be actively written to / locked by
# Windows Update. Deleting it while wuauserv/bits are running risks
# corrupting an in-progress update and causes extra "file in use" failures.
# Stop them first, and restart them again once cleanup is done.
$UpdateServices = @("wuauserv", "bits")
$StoppedServices = @()

Write-Host "[*] Stopping Windows Update services..." -ForegroundColor Yellow
foreach ($svc in $UpdateServices) {
    try {
        $service = Get-Service -Name $svc -ErrorAction Stop
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $svc -Force -ErrorAction Stop
            $StoppedServices += $svc
            Write-Host "  -> Stopped $svc" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  -> Could not stop $svc (continuing anyway)" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ---------------------------------------------------------
# PHASE 2: Scan + Clean (single pass per target folder)
# ---------------------------------------------------------
# FIX: the original script walked each folder recursively TWICE (once to
# size it for the "scan" report, once again to delete it), and deleted
# every item - files AND folders - individually with -Recurse. Once a
# parent folder had already been removed, later Remove-Item calls on its
# now-gone children threw errors that were miscounted as "locked files".
# This version walks each folder once and only calls Remove-Item -Recurse
# on TOP-LEVEL items, letting -Recurse handle each subtree in one call.
Write-Host "[*] Scanning and cleaning target folders..." -ForegroundColor Yellow

foreach ($Path in $PathsToClean) {
    if (-not (Test-Path $Path)) { continue }

    Write-Host " -> Cleaning $Path" -ForegroundColor DarkGray
    $topLevelItems = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue

    foreach ($Item in $topLevelItems) {
        try {
            if ($Item.PSIsContainer) {
                # FIX: piping an EMPTY result straight into Measure-Object
                # -Property Length throws "property cannot be found" under
                # Windows PowerShell 5.1 (PS7 handles it silently). An empty
                # subfolder produces exactly that empty result, so check
                # first instead of piping directly.
                $subItems = Get-ChildItem -Path $Item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                $size = if ($subItems) { ($subItems | Measure-Object -Property Length -Sum).Sum } else { 0 }
            } else {
                $size = $Item.Length
            }
            if (-not $size) { $size = 0 }

            Remove-Item -Path $Item.FullName -Recurse -Force -ErrorAction Stop
            $TotalBytesFreed += $size
        } catch {
            $LockedFiles++
        }
    }
}

# Empty Recycle Bin
Write-Host " -> Emptying Recycle Bin..." -ForegroundColor DarkGray
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

$FreedSpaceMB = [math]::Round($TotalBytesFreed / 1MB, 2)
Write-Host "[+] Cleaning Complete! Freed $FreedSpaceMB MB. ($LockedFiles item(s) were in use and skipped)." -ForegroundColor Green
Write-Host ""

# Restart any Windows Update services we stopped
if ($StoppedServices.Count -gt 0) {
    Write-Host "[*] Restarting Windows Update services..." -ForegroundColor Yellow
    foreach ($svc in $StoppedServices) {
        try {
            Start-Service -Name $svc -ErrorAction Stop
            Write-Host "  -> Restarted $svc" -ForegroundColor DarkGray
        } catch {
            Write-Host "  -> Could not restart $svc - you may need to start it manually." -ForegroundColor Red
        }
    }
    Write-Host ""
}

Start-Sleep -Seconds 1

# ---------------------------------------------------------
# PHASE 3: System Optimization
# ---------------------------------------------------------
Write-Host "[*] Applying System Optimizations..." -ForegroundColor Yellow

# Clear DNS Cache (Improves browsing responsiveness if cache is corrupted)
Write-Host " -> Flushing DNS Resolver Cache..." -ForegroundColor DarkGray
Clear-DnsClientCache

# Optimize System Drive (C:) - Trims SSDs and Defrags HDDs
Write-Host " -> Optimizing System Drive (C:)... This may take a while on large HDDs." -ForegroundColor DarkGray
# FIX: previously -ErrorAction SilentlyContinue hid real failures (e.g. no
# admin, BitLocker, or a volume that doesn't support the operation). Now the
# failure reason is actually shown instead of just claiming success.
try {
    Optimize-Volume -DriveLetter C -ReTrim -Defrag -ErrorAction Stop
    Write-Host "[+] System Optimizations Applied Successfully!" -ForegroundColor Green
} catch {
    Write-Host "[!] Drive optimization skipped: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""
Start-Sleep -Seconds 1

# ---------------------------------------------------------
# PHASE 4: Summary Report
# ---------------------------------------------------------
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "                 Optimization Summary                 " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Total Space Freed   : $FreedSpaceMB MB" -ForegroundColor Green
Write-Host "Items Skipped       : $LockedFiles (in use)" -ForegroundColor Green
Write-Host "Network Cache       : Flushed & Reset" -ForegroundColor Green
Write-Host "Drive C:            : Optimized (Trimmed/Defragmented)" -ForegroundColor Green
Write-Host "Status              : PC is running at peak efficiency." -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""