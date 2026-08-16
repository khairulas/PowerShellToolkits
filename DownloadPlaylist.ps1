<#
.SYNOPSIS
    Batch downloads a YouTube playlist into a structured folder.
.DESCRIPTION
    Uses yt-dlp to download every video in a playlist at a chosen resolution
    ceiling, numbering files in playlist order and encoding for PowerPoint
    compatibility (H.264/AAC/yuv420p).
.PARAMETER Url
    The YouTube playlist URL.
.PARAMETER ResolutionChoice
    "1"/"2"=4K, "3"=2K, "4"=1080p (default), "5"=720p, "6"=480p.
.PARAMETER BaseOutputDirectory
    Folder to save playlist subfolders into. Defaults to your Videos folder.
.EXAMPLE
    .\DownloadPlaylist.ps1
#>

function Download-YouTubePlaylist {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [string]$ResolutionChoice,
        [string]$BaseOutputDirectory = "$env:USERPROFILE\Videos"
    )

    # 1. Verify yt-dlp installation
    if (-not (Get-Command "yt-dlp" -ErrorAction SilentlyContinue)) {
        Write-Error "yt-dlp not found. Ensure it is installed via 'winget install yt-dlp FFmpeg' and your terminal was restarted."
        return
    }

    # FIX: require something that actually looks like an http(s) URL, so a
    # string starting with "-" can't be misread by yt-dlp as a flag.
    if ($Url -notmatch '^(https?://)') {
        Write-Error "That doesn't look like a valid http(s) URL: $Url"
        return
    }

    # 2. Map resolution limits
    $resLimit = switch ($ResolutionChoice) {
        "1" { "2160" } # 4K
        "2" { "2160" }
        "3" { "1440" }
        "4" { "1080" }
        "5" { "720" }
        "6" { "480" }
        Default { "1080" }
    }

    Write-Host "`n--- Starting Playlist Download ---" -ForegroundColor Cyan
    Write-Host "Fetching playlist metadata..." -ForegroundColor Gray

    <#
    PLAYLIST FLAGS:
    --yes-playlist              : Enforces downloading the entire playlist.
    -o ".../%(playlist_title)s/...": Creates a subfolder named after the playlist.
    %(playlist_index)s - %(title)s.%(ext)s : Numbers videos in order (01, 02, etc.).
    --postprocessor-args        : Forces H.264/AAC/yuv420p during the merge step
                                   for PowerPoint compatibility.

    FIX: the original command also added --recode-video mp4, which forces a
    SECOND full re-encode pass on top of the one already forced by
    --postprocessor-args during the merge - a redundant, CPU-expensive,
    quality-losing extra transcode for no benefit. Dropping it here; the
    merge step alone already produces PowerPoint-ready output.
    #>
    yt-dlp --yes-playlist `
        -f "bestvideo[height<=$resLimit]+bestaudio/best[height<=$resLimit]" `
        --merge-output-format mp4 `
        --postprocessor-args "ffmpeg:-vcodec libx264 -acodec aac -pix_fmt yuv420p" `
        -o "$BaseOutputDirectory\%(playlist_title)s\%(playlist_index)s - %(title)s.%(ext)s" `
        $Url

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nPlaylist Download Complete!" -ForegroundColor Green
        Write-Host "Files saved to: $BaseOutputDirectory" -ForegroundColor Gray
    } else {
        Write-Host "`nAn error occurred while downloading the playlist." -ForegroundColor Red
    }
}

# --- User Interface ---
Clear-Host
Write-Host "=== YouTube Playlist Downloader ===" -ForegroundColor Yellow
$url = Read-Host "Enter the YouTube Playlist URL"

Write-Host "`nSelect preferred resolution for all videos:" -ForegroundColor White
Write-Host "1) Max  2) 4K  3) 2K  4) 1080p (Recommended)  5) 720p  6) 480p"
$choice = Read-Host "Choice (1-6)"

if ($url) {
    Download-YouTubePlaylist -Url $url -ResolutionChoice $choice
} else {
    Write-Host "No URL provided. Exiting..." -ForegroundColor Red
}
