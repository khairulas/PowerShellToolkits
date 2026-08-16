function Download-YouTubeVideo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [string]$ResolutionChoice,
        
        [string]$OutputDirectory = "$env:USERPROFILE\Videos"
    )

    # 1. Verification
    if (-not (Get-Command "yt-dlp" -ErrorAction SilentlyContinue)) {
        Write-Error "yt-dlp not found."
        return
    }

    # 2. Resolution mapping
    $resLimit = switch ($ResolutionChoice) {
        "1" { "2160" } # 4K
        "2" { "2160" }
        "3" { "1440" }
        "4" { "1080" }
        "5" { "720" }
        "6" { "480" }
        Default { "1080" }
    }

    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
    }

    Write-Host "`n--- Downloading for PowerPoint Compatibility ---" -ForegroundColor Cyan

    <# 
       KEY CHANGES FOR POWERPOINT:
       -f: We request the best video up to the chosen height.
       --recode-video mp4: Forces the container to MP4.
       --postprocessor-args: This tells FFmpeg to use libx264 (video) and aac (audio).
       -pix_fmt yuv420p: Crucial for PowerPoint/QuickTime compatibility.
    #>
    
    yt-dlp -f "bestvideo[height<=$resLimit]+bestaudio/best[height<=$resLimit]" `
           --merge-output-format mp4 `
           --recode-video mp4 `
           --postprocessor-args "ffmpeg:-vcodec libx264 -acodec aac -pix_fmt yuv420p" `
           -o "$OutputDirectory\%(title)s.%(ext)s" `
           $Url

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nSuccess! This file is now PowerPoint-ready." -ForegroundColor Green
        Write-Host "Location: $OutputDirectory" -ForegroundColor Gray
    } else {
        Write-Host "`nSomething went wrong. Ensure FFmpeg is installed." -ForegroundColor Red
    }
}

# --- Interface ---
Clear-Host
$url = Read-Host "Enter the YouTube Video URL"
Write-Host "`nSelect resolution (Note: 1080p is recommended for PPT stability):"
Write-Host "1) Max  2) 4K  3) 2K  4) 1080p  5) 720p  6) 480p"
$choice = Read-Host "Choice"

Download-YouTubeVideo -Url $url -ResolutionChoice $choice