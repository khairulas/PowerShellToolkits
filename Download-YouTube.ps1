<#
.SYNOPSIS
    Downloads YouTube videos using yt-dlp.
.DESCRIPTION
    Ensures yt-dlp is installed (via winget, Chocolatey, or a direct binary
    download as a last resort), then downloads a video at the requested
    quality.
.PARAMETER Url
    The YouTube video URL to download.
.PARAMETER OutputDir
    Folder to save the download to. Defaults to Downloads\YouTube.
.PARAMETER Quality
    One of: best, 1080p, 720p, 480p, 360p, audio-only.
.EXAMPLE
    .\Download-YouTube.ps1 -Url "https://youtu.be/..."
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$Url,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "$HOME\Downloads\YouTube",

    [Parameter(Mandatory = $false)]
    [ValidateSet("best", "1080p", "720p", "480p", "360p", "audio-only")]
    [string]$Quality = "best"
)

function Write-Header {
    Write-Host ""
    Write-Host " +======================================+" -ForegroundColor Cyan
    Write-Host " |      YouTube Video Downloader         |" -ForegroundColor Cyan
    Write-Host " |         powered by yt-dlp             |" -ForegroundColor Cyan
    Write-Host " +======================================+" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step([string]$msg)    { Write-Host "  >> $msg" -ForegroundColor Yellow }
function Write-Success([string]$msg) { Write-Host "  OK $msg" -ForegroundColor Green }
function Write-Fail([string]$msg)    { Write-Host "  FAILED $msg" -ForegroundColor Red }

function Ensure-YtDlp {
    Write-Step "Checking for yt-dlp..."
    if (Get-Command yt-dlp -ErrorAction SilentlyContinue) {
        Write-Success "yt-dlp found."
        return $true
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step "Installing yt-dlp via winget..."
        winget install yt-dlp.yt-dlp --silent --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("PATH", "User")
            # FIX: previously a 0 exit code from winget was trusted blindly.
            # Confirm yt-dlp is actually resolvable before declaring success.
            if (Get-Command yt-dlp -ErrorAction SilentlyContinue) {
                Write-Success "yt-dlp installed via winget."
                return $true
            }
            Write-Step "winget reported success but yt-dlp isn't on PATH yet - trying next method..."
        }
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Step "Installing yt-dlp via Chocolatey..."
        choco install yt-dlp -y | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
            Write-Success "yt-dlp installed via Chocolatey."
            return $true
        }
    }

    # NOTE: this is a last-resort fallback. It downloads a binary directly
    # from GitHub Releases over HTTPS but does NOT verify a checksum or
    # signature against it, so it's trusting the release artifact itself.
    # Prefer winget/choco above where possible; if you want to harden this
    # further, pin a specific yt-dlp version and verify its published
    # SHA256 checksum before adding it to PATH.
    Write-Step "winget/choco unavailable - downloading yt-dlp binary directly (unverified)..."
    $installDir = "$env:LOCALAPPDATA\yt-dlp"
    $ytDlpPath = "$installDir\yt-dlp.exe"
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    $releaseUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"

    try {
        Invoke-WebRequest -Uri $releaseUrl -OutFile $ytDlpPath -UseBasicParsing
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if ($userPath -notlike "*$installDir*") {
            [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$installDir", "User")
        }
        $env:PATH += ";$installDir"

        if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
            Write-Fail "Downloaded yt-dlp.exe but it isn't resolving on PATH. Try restarting your terminal."
            return $false
        }
        Write-Success "yt-dlp downloaded to $ytDlpPath"
        return $true
    }
    catch {
        Write-Fail "Could not download yt-dlp: $_"
        return $false
    }
}

function Get-FormatString([string]$q) {
    switch ($q) {
        "best"       { return "bestvideo+bestaudio/best" }
        "1080p"      { return "bestvideo[height<=1080]+bestaudio/best[height<=1080]" }
        "720p"       { return "bestvideo[height<=720]+bestaudio/best[height<=720]" }
        "480p"       { return "bestvideo[height<=480]+bestaudio/best[height<=480]" }
        "360p"       { return "bestvideo[height<=360]+bestaudio/best[height<=360]" }
        "audio-only" { return "bestaudio" }
        default      { return "bestvideo+bestaudio/best" }
    }
}

Write-Header

if (-not $Url) {
    $Url = Read-Host " Enter YouTube URL"
}

if ([string]::IsNullOrWhiteSpace($Url)) {
    Write-Fail "No URL provided. Exiting."
    exit 1
}

# FIX: no validation previously existed on the URL at all. A string that
# happens to start with "-" could otherwise be interpreted by yt-dlp as a
# flag rather than a URL. Require it to actually look like an http(s) URL.
if ($Url -notmatch '^(https?://)') {
    Write-Fail "That doesn't look like a valid http(s) URL: $Url"
    exit 1
}

if (-not (Ensure-YtDlp)) {
    Write-Fail "yt-dlp could not be installed. Please install it manually from https://github.com/yt-dlp/yt-dlp"
    exit 1
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Write-Success "Created output folder: $OutputDir"
}

$format = Get-FormatString $Quality
$outputTmpl = Join-Path $OutputDir "%(title)s [%(id)s].%(ext)s"

if ($Quality -eq "audio-only") {
    $ytArgs = @(
        "--format", $format,
        "--output", $outputTmpl,
        "--extract-audio",
        "--audio-format", "mp3",
        "--audio-quality", "0",
        "--add-metadata",
        "--embed-thumbnail",
        $Url
    )
} else {
    $ytArgs = @(
        "--format", $format,
        "--output", $outputTmpl,
        "--merge-output-format", "mp4",
        "--embed-thumbnail",
        "--add-metadata",
        "--no-playlist",
        $Url
    )
}

Write-Step "Starting download..."
Write-Host "   URL     : $Url" -ForegroundColor Gray
Write-Host "   Quality : $Quality" -ForegroundColor Gray
Write-Host "   Folder  : $OutputDir" -ForegroundColor Gray
Write-Host ""

yt-dlp @ytArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Success "Download complete! Files saved to: $OutputDir"
} else {
    Write-Host ""
    Write-Fail "yt-dlp exited with code $LASTEXITCODE. Check the output above for details."
    exit $LASTEXITCODE
}
