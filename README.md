# 🎥 Windows PowerShell Utility & Media Toolkit

A lightweight, powerful suite of PowerShell scripts for downloading media, optimizing Windows performance, and managing local media files[cite: 1, 2, 3, 4]. 

All video tools output **H.264 video** and **AAC audio** (`yuv420p` pixel format) for native **Microsoft PowerPoint** compatibility.

---

## 📋 Prerequisites

Install `yt-dlp`, `FFmpeg`, and `Git` via Windows Package Manager (**winget**) in an Administrator PowerShell window:

```powershell
winget install yt-dlp FFmpeg Git.Git

```

> **Note:** Close and reopen your PowerShell window after installation to refresh environment path variables.

---

## ⚡ Execution Policy Setup

Enable local script execution on your user account by running this once in PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

```

---

## 🛠️ Included Tools

### 🎬 Media Utilities

| Script | Description |
| --- | --- |
| **`DownloadWithResolution.ps1`** | Downloads YouTube videos with target resolution settings (1080p, 4K, etc.) formatted for PowerPoint. |
| **`DownloadMP3.ps1`** | Downloads YouTube audio directly to high-bitrate `.mp3` format in your `Music` directory. |
| **`DownloadPlaylist.ps1`** | Batch downloads YouTube playlists into structured folders with numbered sequence prefixes. |
| **`ConvertMP4ToMP3.ps1`** | Converts single `.mp4` files or entire folders of MP4s into `.mp3` audio tracks. |
| **`CompressVideo.ps1`** | Reduces video file sizes using H.264 CRF encoding with high visual quality retention. |

---

### 🚀 System Optimization Utilities

| Script | Administrator Required | Description |
| --- | --- | --- |
| **`Disable-WindowsSearch.ps1`** | Yes | Stops and disables the `WSearch` service to reduce disk I/O and CPU usage.

 |
| **`Enable-WindowsSearch.ps1`** | Yes | Re-enables and starts the `WSearch` service to restore file indexing capabilities.

 |
| **`Clear-TempFiles.ps1`** | No | Performs a fast purge of user and system temporary folders.

 |
| **`Optimize-System.ps1`** | Yes | Comprehensive PC cleanup: scans junk files, empties Recycle Bin, flushes DNS cache, and trims SSDs/defrags HDDs.

 |

---

## 📖 Detailed Script Usage

### System Cleanup & Performance

* **Disable File Indexing:** Stops background disk indexing.


```powershell
.\Disable-WindowsSearch.ps1

```


* **Restore File Indexing:** Re-enables background search indexing.


```powershell
.\Enable-WindowsSearch.ps1

```


* **Quick Temp Clean:** Clears temporary files safely.


```powershell
.\Clear-TempFiles.ps1

```


* **Full PC Optimization:** Scans space savings, cleans system logs, flushes DNS, and optimizes drive health.


```powershell
.\Optimize-System.ps1

```



---

### Media Downloading & Processing

* **YouTube Video:** `.\DownloadWithResolution.ps1`
* **YouTube MP3:** `.\DownloadMP3.ps1`
* **YouTube Playlist:** `.\DownloadPlaylist.ps1`
* **MP4 to MP3:** `.\ConvertMP4ToMP3.ps1`
* **Compress Video:** `.\CompressVideo.ps1`

---

## 📄 License

Distributed under the MIT License. Free for personal and commercial use.
