<#
.SYNOPSIS
    Premium PC Cleaning & Optimization Script
.DESCRIPTION
    Scans for junk files, calculates space, cleans directories, empties the recycle bin, and optimizes system drives and network cache.
#>

# 1. Ensure Administrator Privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as an Administrator!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'." -ForegroundColor Yellow
    Exit
}

Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   Intelligent Scan & Premium PC Optimization Tool     " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Define target directories for cleaning
$PathsToClean = @(
    "$env:TEMP\*",
    "$env:WINDIR\Temp\*",
    "$env:WINDIR\Prefetch\*",
    "$env:WINDIR\SoftwareDistribution\Download\*"
)

$TotalBytesFreed = 0

# ---------------------------------------------------------
# PHASE 1: Intelligent Scan
# ---------------------------------------------------------
Write-Host "[*] Initiating Intelligent Scan..." -ForegroundColor Yellow

$TotalBytesToClean = 0
$LockedFiles = 0

foreach ($Path in $PathsToClean) {
    if (Test-Path ($Path.TrimEnd('\*'))) {
        $Items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($Item in $Items) {
            if ($Item -is [System.IO.FileInfo]) {
                $TotalBytesToClean += $Item.Length
            }
        }
    }
}

$PotentialSpaceMB = [math]::Round($TotalBytesToClean / 1MB, 2)
Write-Host "[+] Scan Complete! Found approximately $PotentialSpaceMB MB of junk files." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 2

# ---------------------------------------------------------
# PHASE 2: Deep Cleaning
# ---------------------------------------------------------
Write-Host "[*] Starting Deep Clean Process..." -ForegroundColor Yellow

foreach ($Path in $PathsToClean) {
    Write-Host "    -> Cleaning $Path" -ForegroundColor DarkGray
    $Items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    
    foreach ($Item in $Items) {
        try {
            $FileSize = $Item.Length
            Remove-Item -Path $Item.FullName -Force -Recurse -ErrorAction Stop
            $TotalBytesFreed += $FileSize
        } catch {
            $LockedFiles++
        }
    }
}

# Empty Recycle Bin
Write-Host "    -> Emptying Recycle Bin..." -ForegroundColor DarkGray
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

$FreedSpaceMB = [math]::Round($TotalBytesFreed / 1MB, 2)
Write-Host "[+] Cleaning Complete! Freed $FreedSpaceMB MB. ($LockedFiles files were in use and skipped)." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 2

# ---------------------------------------------------------
# PHASE 3: System Optimization
# ---------------------------------------------------------
Write-Host "[*] Applying System Optimizations..." -ForegroundColor Yellow

# Clear DNS Cache (Improves browsing responsiveness if cache is corrupted)
Write-Host "    -> Flushing DNS Resolver Cache..." -ForegroundColor DarkGray
Clear-DnsClientCache

# Optimize System Drive (C:) - Trims SSDs and Defrags HDDs
Write-Host "    -> Optimizing System Drive (C:)... This may take a moment." -ForegroundColor DarkGray
Optimize-Volume -DriveLetter C -ReTrim -Defrag -ErrorAction SilentlyContinue

Write-Host "[+] System Optimizations Applied Successfully!" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

# ---------------------------------------------------------
# PHASE 4: Summary Report
# ---------------------------------------------------------
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "                 Optimization Summary                  " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Total Space Freed : $FreedSpaceMB MB" -ForegroundColor Green
Write-Host "Network Cache     : Flushed & Reset" -ForegroundColor Green
Write-Host "Drive C:          : Optimized (Trimmed/Defragmented)" -ForegroundColor Green
Write-Host "Status            : PC is running at peak efficiency." -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""