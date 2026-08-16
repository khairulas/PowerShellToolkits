<#
.SYNOPSIS
    Converts MP4 video file(s) to MP3 audio using FFmpeg.
.DESCRIPTION
    Accepts a single .mp4 file or a folder of .mp4 files and extracts the
    audio track to .mp3 alongside the source file(s).
.PARAMETER Path
    Path to an .mp4 file or a folder containing .mp4 files.
.PARAMETER AudioBitrate
    Target audio bitrate, e.g. "320k" (default).
.EXAMPLE
    .\ConvertMP4ToMP3.ps1
#>

function Convert-Mp4ToMp3 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$AudioBitrate = "320k"
    )

    # 1. Check if FFmpeg is installed
    if (-not (Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) {
        Write-Error "FFmpeg not found. Please install it using 'winget install FFmpeg' in an Administrator terminal."
        return
    }

    # 2. Resolve input path
    if (-not (Test-Path $Path)) {
        Write-Error "The path '$Path' does not exist."
        return
    }

    $item = Get-Item $Path
    $successCount = 0
    $failCount = 0

    # 3. Handle single file vs directory batch conversion
    if ($item.PSIsContainer) {
        # Processing a Directory
        $files = Get-ChildItem -Path $Path -Filter "*.mp4"

        if ($files.Count -eq 0) {
            Write-Host "No .mp4 files found in directory." -ForegroundColor Yellow
            return
        }

        Write-Host "`nFound $($files.Count) MP4 file(s). Starting conversion..." -ForegroundColor Cyan

        foreach ($file in $files) {
            $outputFile = [System.IO.Path]::ChangeExtension($file.FullName, ".mp3")
            Write-Host "Converting: $($file.Name)..." -ForegroundColor Gray
            ffmpeg -i "$($file.FullName)" -vn -ab $AudioBitrate -ar 44100 -y "$outputFile" 2>$null

            # FIX: previously $LASTEXITCODE was only checked once, after the
            # whole loop, so it only ever reflected the LAST file processed.
            # A failure on an earlier file in the batch was silently ignored.
            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputFile)) {
                $successCount++
            } else {
                Write-Host "  Failed: $($file.Name) (FFmpeg exit code: $LASTEXITCODE)" -ForegroundColor Red
                $failCount++
            }
        }

        $summaryColor = if ($failCount -eq 0) { "Green" } else { "Yellow" }
        Write-Host "`nBatch complete: $successCount converted, $failCount failed." -ForegroundColor $summaryColor
    } else {
        # Processing a Single File
        if ($item.Extension -ne ".mp4") {
            Write-Error "The specified file is not an .mp4 file."
            return
        }

        $outputFile = [System.IO.Path]::ChangeExtension($item.FullName, ".mp3")
        Write-Host "`nConverting: $($item.Name)..." -ForegroundColor Cyan

        <#
        FFMPEG FLAGS:
        -i   : Input file
        -vn  : Disable video recording (audio track only)
        -ab  : Audio bitrate (320k for max quality)
        -ar  : Audio sampling rate (44100 Hz)
        -y   : Overwrite output file if it exists
        #>
        ffmpeg -i "$($item.FullName)" -vn -ab $AudioBitrate -ar 44100 -y "$outputFile" 2>$null

        if ($LASTEXITCODE -eq 0 -and (Test-Path $outputFile)) {
            $successCount++
        } else {
            $failCount++
        }
    }

    if ($failCount -eq 0 -and $successCount -gt 0) {
        Write-Host "`nConversion Complete!" -ForegroundColor Green
    } elseif ($successCount -gt 0) {
        Write-Host "`nCompleted with errors: $successCount succeeded, $failCount failed." -ForegroundColor Yellow
    } else {
        Write-Host "`nAn error occurred during conversion." -ForegroundColor Red
    }
}

# --- User Interface ---
Clear-Host
Write-Host "=== Local MP4 to MP3 Converter ===" -ForegroundColor Yellow

$inputPath = Read-Host "Enter the path to an MP4 file or folder containing MP4 files"

# Strip surrounding quotation marks if copied via "Copy as path"
$cleanPath = $inputPath.Trim('"')

if ($cleanPath) {
    Convert-Mp4ToMp3 -Path $cleanPath
} else {
    Write-Host "No path provided. Exiting..." -ForegroundColor Red
}
