<#
.SYNOPSIS
    Downloads YouTube audio directly as a high-bitrate MP3.
.DESCRIPTION
    Uses yt-dlp to extract and convert audio from a YouTube URL, saving it
    to the Music folder by default.
.PARAMETER Url
    The YouTube video URL to extract audio from.
.PARAMETER OutputDirectory
    Folder to save the MP3 to. Defaults to your Windows Music folder.
.EXAMPLE
    .\DownloadMP3.ps1
#>

function Download-YouTubeAudio {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [string]$OutputDirectory = "$env:USERPROFILE\Music"
    )

    # 1. Check if tools are available
    if (-not (Get-Command "yt-dlp" -ErrorAction SilentlyContinue)) {
        Write-Error "yt-dlp not found. Please run 'winget install yt-dlp FFmpeg' in a new Administrator terminal."
        return
    }

    # FIX: no URL validation previously existed. Require something that
    # actually looks like an http(s) URL so a string starting with "-"
    # can't be misread by yt-dlp as a command-line flag.
    if ($Url -notmatch '^(https?://)') {
        Write-Error "That doesn't look like a valid http(s) URL: $Url"
        return
    }

    # 2. Ensure output directory exists (Defaults to your Windows Music folder)
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
    }

    Write-Host "`n--- Starting MP3 Extraction ---" -ForegroundColor Cyan
    Write-Host "Target Folder: $OutputDirectory" -ForegroundColor Gray

    <#
    MP3 CONVERSION FLAGS:
    -x                  : Extract audio only
    --audio-format mp3  : Convert to MP3
    --audio-quality 0   : Best variable bitrate (VBR) quality (~250-320 kbps)
    #>
    yt-dlp -x `
        --audio-format mp3 `
        --audio-quality 0 `
        -o "$OutputDirectory\%(title)s.%(ext)s" `
        $Url

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nAudio Download Complete!" -ForegroundColor Green
        Write-Host "File saved in your Music folder." -ForegroundColor Gray
    } else {
        Write-Host "`nAn error occurred during audio extraction." -ForegroundColor Red
    }
}

# --- User Interface ---
Clear-Host
Write-Host "=== YouTube to MP3 Converter ===" -ForegroundColor Yellow
$url = Read-Host "Enter the YouTube Video URL"

if ($url) {
    Download-YouTubeAudio -Url $url
} else {
    Write-Host "No URL provided. Exiting..." -ForegroundColor Red
}
