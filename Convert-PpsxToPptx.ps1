<#
.SYNOPSIS
    Converts PowerPoint Show (.ppsx) files to standard Presentations (.pptx).
#>
function Convert-PpsxToPptx {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    if (-not (Test-Path $FolderPath)) {
        Write-Error "The path '$FolderPath' does not exist."
        return
    }

    $files = Get-ChildItem -Path $FolderPath -Filter "*.ppsx"
    if ($files.Count -eq 0) {
        Write-Host "No .ppsx files found in $FolderPath" -ForegroundColor Yellow
        return
    }

    Write-Host "`nFound $($files.Count) .ppsx files. Starting conversion..." -ForegroundColor Cyan
    
    # Launch PowerPoint invisibly in the background
    try {
        $ppt = New-Object -ComObject PowerPoint.Application
    } catch {
        Write-Error "Failed to start PowerPoint. Ensure Microsoft Office is installed on this PC."
        return
    }

    foreach ($file in $files) {
        $newFileName = [System.IO.Path]::ChangeExtension($file.FullName, ".pptx")
        
        # Skip if the .pptx already exists (prevents overwriting)
        if (Test-Path $newFileName) {
            Write-Host "Skipping: $($file.Name) (PPTX version already exists)" -ForegroundColor DarkGray
            continue
        }

        Write-Host "Converting: $($file.Name)..." -ForegroundColor Gray
        
        try {
            # Open presentation (ReadOnly=True, Untitled=False, WithWindow=False)
            $presentation = $ppt.Presentations.Open($file.FullName, $true, $false, $false)
            
            # SaveAs Format 24 = ppSaveAsOpenXMLPresentation (.pptx)
            $presentation.SaveAs($newFileName, 24)
            $presentation.Close()
            
            Write-Host "  -> Success" -ForegroundColor Green
        } catch {
            Write-Host "  -> Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Cleanup memory and close background PowerPoint process
    $ppt.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    Write-Host "`nAll conversions complete!" -ForegroundColor Green
}

# --- User Interface ---
Clear-Host
Write-Host "=== PPSX to PPTX Batch Converter ===" -ForegroundColor Yellow
$inputPath = Read-Host "Enter the folder path containing your .ppsx files"

# Strip surrounding quotation marks if copied via "Copy as path"
$cleanPath = $inputPath.Trim('"')

if ($cleanPath) {
    Convert-PpsxToPptx -FolderPath $cleanPath
} else {
    Write-Host "No path provided. Exiting..." -ForegroundColor Red
}