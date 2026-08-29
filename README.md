# 🎥 Windows PowerShell Utility & Media Toolkit

A lightweight, powerful suite of PowerShell scripts for downloading media, optimizing Windows performance, and managing local media files[cite: 5].

All video tools output **H.264 video** and **AAC audio** (`yuv420p` pixel format) for native **Microsoft PowerPoint** compatibility[cite: 5].

---

## 📋 Prerequisites

Install `yt-dlp`, `FFmpeg`, and `Git` via Windows Package Manager (**winget**) in an Administrator PowerShell window[cite: 5]:

```powershell
winget install yt-dlp FFmpeg Git.Git

```

> **Note:** Close and reopen your PowerShell window after installation to refresh environment path variables.
> 
> 

---

## ⚡ Execution Policy Setup

To run these scripts you need local script execution enabled. The narrowest option is to allow it just for the PowerShell session you're using, which doesn't change anything for the rest of your system:

```powershell
powershell -ExecutionPolicy Bypass -File .\ScriptName.ps1

```

If you'd rather set a policy once for your account so you can just double-click or `.\Script.ps1` directly, this is a broader, persistent change — it affects every unsigned script you run under your user profile, not just this toolkit:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

```

---

## 🛠️ Included Tools

### 🎬 Media Utilities

| Script | Description |
| --- | --- |
| **`DownloadWithResolution.ps1`** | Downloads YouTube videos with target resolution settings (1080p, 4K, etc.) formatted for PowerPoint.

 |
| **`DownloadMP3.ps1`** | Downloads YouTube audio directly to high-bitrate `.mp3` format in your `Music` directory.

 |
| **`DownloadPlaylist.ps1`** | Batch downloads YouTube playlists into structured folders with numbered sequence prefixes.

 |
| **`ConvertMP4ToMP3.ps1`** | Converts single `.mp4` files or entire folders of MP4s into `.mp3` audio tracks.

 |
| **`CompressVideo.ps1`** | Reduces video file sizes using H.264 CRF encoding with high visual quality retention.

 |
| **`Convert-PpsxToPptx.ps1`** | Batch converts PowerPoint Show (.ppsx) files into editable standard Presentations (.pptx). |
| **`Download-WebFiles.ps1`** | Scrapes and downloads specific files (like .pdf, .ppsx) from public web pages. |

### 🚀 System Optimization Utilities

| Script | Administrator Required | Description |
| --- | --- | --- |
| **`disable-windows-indexer.ps1`** | Yes | Stops and disables the `WSearch` service to reduce disk I/O and CPU usage.

 |
| **`enable-windows-indexer.ps1`** | Yes | Re-enables and starts the `WSearch` service to restore file indexing.

 |
| **`junk-cleaner.ps1`** | No (partial without) | Fast purge of temp folders. Without admin, only your user Temp folder is cleared.

 |
| **`PremiumOptimizer.ps1`** | Yes | Comprehensive PC cleanup: scans junk files, empties Recycle Bin, flushes DNS cache, and trims SSDs/defrags HDDs.

 |

---

## 📖 Detailed Script Usage

### System Cleanup & Performance

* **Disable File Indexing:** Stops background disk indexing.
`.\disable-windows-indexer.ps1`


* **Restore File Indexing:** Re-enables background search indexing.
`.\enable-windows-indexer.ps1`


* **Quick Temp Clean:** Clears temporary files and reports how much was actually freed.
`.\junk-cleaner.ps1`


* **Full PC Optimization:** Scans space savings, cleans system logs, flushes DNS, and optimizes drive health.
`.\PremiumOptimizer.ps1`



---

### Media Downloading & Processing

* **YouTube Video:** `.\DownloadWithResolution.ps1`

* **YouTube MP3:** `.\DownloadMP3.ps1`

* **YouTube Playlist:** `.\DownloadPlaylist.ps1`

* **MP4 to MP3:** `.\ConvertMP4ToMP3.ps1`

* **Compress Video:** `.\CompressVideo.ps1`

* **Convert PPSX to PPTX:** `.\Convert-PpsxToPptx.ps1`
* **Web Page Scraper:** `.\Download-WebFiles.ps1`

---

## 💻 Bonus: JavaScript Mass Downloader (For Authenticated Portals)

If a university portal (like uFuture) blocks PowerShell scripts from downloading files due to login sessions or JavaScript-rendered pages, use this browser console trick instead:

1. Open the portal page containing the files in Chrome/Edge.
2. Press **F12** to open Developer Tools and go to the **Console** tab.
3. Paste this code and hit **Enter**:

```javascript
let links = document.querySelectorAll("a[href*='download'], a[href$='.ppsx'], a[href$='.pptx'], a[href$='.pdf']");
let delay = 0;

links.forEach(link => {
    setTimeout(() => {
        let a = document.createElement('a');
        a.href = link.href;
        a.download = '';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    }, delay);
    delay += 500;
});
console.log(`Triggered ${links.length} downloads!`);

```

---

## 📄 License

Distributed under the MIT License. Free for personal and commercial use.
