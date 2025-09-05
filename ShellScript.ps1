param (
    [string]$folder = "Generic",
    [switch]$video = $false
)

if ($video) {
  Write-Host "Downloading only Videos. Saving media on >> $folder << folder..."  
} else {
    Write-Host "Downloading Playlist or Video. Saving media on >> $folder << folder..."
}

$date = Get-Date -Format "yyMMdd"
$log_name = "$date`_$folder.log"
$log_folder = Join-Path $PSScriptRoot "Logs"
$log_path = Join-Path $log_folder $log_name

New-Item -Path $log_folder -ItemType "Directory" -Force > $null

if ($video) {
   f:\YTdlp\download-scripts-main\Main.ps1 -folder $folder -video | Tee-Object -FilePath $log_path -Append
} else {
   f:\YTdlp\download-scripts-main\Main.ps1 -folder $folder | Tee-Object -FilePath $log_path -Append
}

Pause