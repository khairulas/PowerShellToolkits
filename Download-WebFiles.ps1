function Download-WebFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [string]$OutputDirectory = "$env:USERPROFILE\Downloads\WebScraper",
        
        [string]$CookieString = "",
        
        [string[]]$Extensions = @(".ppsx", ".pptx", ".pdf", ".doc", ".docx", ".zip", ".rar")
    )

    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
    }

    Write-Host "`n--- Starting Web File Scraper ---" -ForegroundColor Cyan
    Write-Host "Scanning: $Url" -ForegroundColor Gray

    # --- THE FIX: Disguise PowerShell as Google Chrome ---
    $headers = @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    
    if ($CookieString) {
        $headers["Cookie"] = $CookieString
        Write-Host "Using provided session cookies for authentication." -ForegroundColor Yellow
    }

    try {
        # Fetch the webpage content
        $request = Invoke-WebRequest -Uri $Url -Headers $headers -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "`nFailed to access the page." -ForegroundColor Red
        # --- THE FIX: Print the exact server error message ---
        Write-Host "Server Error: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    $regexPattern = ($Extensions | ForEach-Object { "\$_$" }) -join "|"
    
    $fileLinks = $request.Links | Where-Object { 
        $_.href -match $regexPattern -or $_.href -match "download" 
    } | Select-Object -Unique href

    if ($fileLinks.Count -eq 0) {
        Write-Host "No downloadable files found on this page." -ForegroundColor Red
        return
    }

    Write-Host "Found $($fileLinks.Count) potential files. Starting download..." -ForegroundColor Cyan

    $count = 1
    foreach ($link in $fileLinks) {
        $downloadUrl = $link.href
        if ($downloadUrl -match "^/") {
            $uri = [System.Uri]$Url
            $downloadUrl = "$($uri.Scheme)://$($uri.Host)$downloadUrl"
        }

        $fileName = [System.IO.Path]::GetFileName($downloadUrl)
        if (-not $fileName -or $fileName -match "\?") {
            $fileName = "DownloadedFile_$count.dat"
        }

        $outputPath = Join-Path $OutputDirectory $fileName
        Write-Host "Downloading [$count/$($fileLinks.Count)]: $fileName" -ForegroundColor Gray

        try {
            Invoke-WebRequest -Uri $downloadUrl -Headers $headers -OutFile $outputPath -UseBasicParsing -ErrorAction Stop
            Write-Host "  -> Success" -ForegroundColor Green
        } catch {
            Write-Host "  -> Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        $count++
    }

    Write-Host "`nFinished processing webpage." -ForegroundColor Green
    Write-Host "Files saved to: $OutputDirectory" -ForegroundColor Gray
}

# --- User Interface ---
Clear-Host
Write-Host "=== Web Page File Downloader ===" -ForegroundColor Yellow
$url = Read-Host "Enter the webpage URL"
$cookie = Read-Host "Enter Cookie string (Leave blank if the page is public)"

if ($url) {
    Download-WebFiles -Url $url -CookieString $cookie
}