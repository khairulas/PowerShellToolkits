<#
.SYNOPSIS
    Downloads a single YouTube video at a chosen resolution, encoded for
    PowerPoint compatibility.
.DESCRIPTION
    Uses yt-dlp to fetch the best video/audio up to a resolution ceiling and
    forces H.264/AAC/yuv420p output.
.PARAMETER Url
    The YouTube video URL.
.PARAMETER ResolutionChoice
    "1"/"2"=4K, "3"=2K, "4"=1080p (recommended), "5"=720p, "6"=480p.
.PARAMETER OutputDirectory
    Folder to save the video to. Defaults to your Videos folder.
.EXAMPLE
    .\DownloadWithResolution.ps1
#>

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

    # FIX: require something that actually looks like an http(s) URL, so a
    # string starting with "-" can't be misread by yt-dlp as a flag.
    if ($Url -notmatch '^(https?://)') {
        Write-Error "That doesn't look like a valid http(s) URL: $Url"
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
    -f                     : Requests the best video/audio up to the chosen height.
    --merge-output-format mp4 : Container is MP4.
    --postprocessor-args   : Forces libx264 (video) / aac (audio) / yuv420p during merge.

    FIX: the original command also added --recode-video mp4, forcing a
    SECOND full re-encode pass on top of what --postprocessor-args already
    forces at merge time. That's a redundant, CPU-expensive, quality-losing
    extra transcode - removed here.
    #>
    yt-dlp -f "bestvideo[height<=$resLimit]+bestaudio/best[height<=$resLimit]" `
        --merge-output-format mp4 `
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
