function Compress-Video {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [string]$CompressionLevel = "2"
    )

    # 1. Verify FFmpeg installation
    if (-not (Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) {
        Write-Error "FFmpeg not found. Run 'winget install FFmpeg' in an Administrator terminal."
        return
    }

    # 2. Map compression level to Constant Rate Factor (CRF)
    # Lower CRF = higher quality / larger file. Higher CRF = lower quality / smaller file.
    $crf = switch ($CompressionLevel) {
        "1" { "20" } # Low compression (Best visual quality, ~20-30% reduction)
        "2" { "24" } # Medium compression (Recommended balance, ~40-60% reduction)
        "3" { "28" } # High compression (Max size drop, slight visual loss)
        Default { "24" }
    }

    if (-not (Test-Path $Path)) {
        Write-Error "The path '$Path' does not exist."
        return
    }

    $item = Get-Item $Path

    # Helper script block to process individual files
    $processFile = {
        param($file, $targetCrf)

        $outputDirectory = "$($file.DirectoryName)\Compressed"
        if (-not (Test-Path $outputDirectory)) {
            New-Item -ItemType Directory -Path $outputDirectory | Out-Null
        }

        $outputFile = Join-Path $outputDirectory "$($file.BaseName)_compressed.mp4"
        Write-Host "Compressing: $($file.Name)..." -ForegroundColor Cyan

        <#
           FFMPEG COMPRESSION FLAGS:
           -vcodec libx264 : standard, highly efficient H.264 video codec
           -crf $targetCrf : controls compression quality
           -preset slow     : spends more CPU time optimizing file size efficiency
           -acodec aac     : standard audio compression
           -b:a 128k        : sets audio bitrate to clean, efficient 128kbps
           -pix_fmt yuv420p : maintains broad playback compatibility (e.g. PowerPoint)
        #>
        ffmpeg -i "$($file.FullName)" `
               -vcodec libx264 `
               -crf $targetCrf `
               -preset slow `
               -acodec aac `
               -b:a 128k `
               -pix_fmt yuv420p `
               -y "$outputFile" 2>$null

        if (Test-Path $outputFile) {
            $origSize = [math]::Round(($file.Length / 1MB), 2)
            $newSize = [math]::Round(((Get-Item $outputFile).Length / 1MB), 2)
            $saved = [math]::Round((($origSize - $newSize) / $origSize) * 100, 1)

            Write-Host "  Done -> Original: ${origSize}MB | Compressed: ${newSize}MB | Saved: ${saved}%" -ForegroundColor Green
        }
    }

    # 3. Process Directory vs Single File
    if ($item.PSIsContainer) {
        $files = Get-ChildItem -Path $Path -Include "*.mp4","*.mov","*.mkv","*.avi" -Recurse
        if ($files.Count -eq 0) {
            Write-Host "No compatible video files found in target folder." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nFound $($files.Count) video(s). Starting batch compression..." -ForegroundColor Yellow
        foreach ($file in $files) {
            & $processFile $file $crf
        }
    } else {
        & $processFile $item $crf
    }
}

# --- User Interface ---
Clear-Host
Write-Host "=== Video Size Reducer ===" -ForegroundColor Yellow
$inputPath = Read-Host "Enter file or folder path"
$cleanPath = $inputPath.Trim('"')

Write-Host "`nSelect Compression Level:" -ForegroundColor White
Write-Host "1) Low Compression    (Higher Quality, Larger File)"
Write-Host "2) Medium Compression (Balanced - Recommended)"
Write-Host "3) High Compression   (Smallest File, Lower Quality)"
$levelChoice = Read-Host "Choice (1-3)"

if ($cleanPath) {
    Compress-Video -Path $cleanPath -CompressionLevel $levelChoice
} else {
    Write-Host "No path provided. Exiting..." -ForegroundColor Red
}