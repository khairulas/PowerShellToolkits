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
       --yes-playlist                       : Enforces downloading the entire playlist.
       -o ".../%(playlist_title)s/..."     : Creates a subfolder named after the playlist.
       %(playlist_index)s - %(title)s.%(ext)s: Numbers videos in chronological order (01, 02, etc.).
       --postprocessor-args                 : Guarantees H.264/AAC encoding for PowerPoint compatibility.
    #>
    
    yt-dlp --yes-playlist `
           -f "bestvideo[height<=$resLimit]+bestaudio/best[height<=$resLimit]" `
           --merge-output-format mp4 `
           --recode-video mp4 `
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