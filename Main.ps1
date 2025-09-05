param (
    [Parameter(Mandatory=$true)][string]$url,
    [string]$folder = "Generic",
    [string]$tool_path = "f:\YTdlp\",
    [string]$ffmpeg_path = "f:\YTdlp\ffmpeg-master-latest-win64-gpl\bin\",
    [switch]$video = $false
)

# Get correct path separator
# $tool_path = Get-Item $tool_path
# $tool_path = $tool_path.FullName
# $ffmpeg_path = Get-Item $ffmpeg_path
# $ffmpeg_path = $ffmpeg_path.FullName

if (!$url) {
    Write-Error "Empty URL is not valid!"
    exit 1
} else {
    # Set tool environment variable to path

    # $temp = $env:Path
    # Write-Host $temp
    # Write-Host $temp.GetType()
    # $temp += ";$tool_path"
    # Write-Host $temp
    # Write-Host $temp.GetType()
}

function Get-CleanURL {
    param (
        [string]$url,
        [string]$youtube_param = "list"
    )
# https://stackoverflow.com/questions/51951559/grab-parameters-from-url-and-drop-them-to-powershell-variables
    if ($url -is [uri]) {
        $url = $url.ToString()
    }
    # test if the url has a query string
    if ($url.IndexOf('?') -ge 0) {
        $components = ($url -split '\?')
        $domain = $components[0]
        # get the part of the url after the question mark to get the query string
        $query = $components[1]    
        # or use: $query = $url.Substring($url.IndexOf('?') + 1)

        # remove possible fragment part of the query string
        $query = $query.Split('#')[0]

        # detect variable names and their values in the query string
        # and store them in a Hashtable
        $queryHash = @{}
        foreach ($q in ($query -split '&')) {
            $kv = $($q + '=') -split '='
            $name = [uri]::UnescapeDataString($kv[0]).Trim()
            $queryHash[$name] = [uri]::UnescapeDataString($kv[1])
        }
        # $queryHash
    }
    else {
        Write-Host "No query string found as part of the given URL"
        return $url
    }

    if ($queryHash.ContainsKey($youtube_param)) {
        $list_id = $queryHash[$youtube_param]
        $url = "{0}?{1}={2}" -f $domain, $youtube_param, $list_id
        Write-Output $url
    } else {
        Write-Warning "YouTube [$youtube_param] parameter not found"
        Write-Host $queryHash
        Write-Host ""
        # Write-Output $url
        Write-Output $domain # Return video only [https://youtu.be/-7xOTbRL888?list=RDGMEMCMFH2exzjBeE_zAHHJOdxg]
    }

}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$date = Get-Date -Format "yyMMdd"
$source = "YouTube" # Default
$write_metadata = $false # Don't write thumbnail, JSON, description, etc.
$playlist_path = ""

$msg = "{0}: Running script..." -f $timestamp
Write-Output ""
Write-Output "################################################################################"
Write-Output $msg
Write-Output ""

$is_youtube_playlist = $false

if (Test-Path -Path $url -PathType Leaf) {
    Write-Output "The file '$url' exists."
    # Perform actions if the file exists
    exit 0
} elseif ($url -like "https://x.com/*") {
    $source = "Twitter"
    $folder = "" # Don't use folder for Twitter videos
    $write_metadata = $true # Write thumbnail, JSON, description, etc.
} elseif ($url -like "*www.tiktok.com*") {
    $source = "TikTok"
    # $folder = "" # Don't use folder for Twitter videos
    $write_metadata = $true # Write thumbnail, JSON, description, etc.
} elseif ($url -like "*list=*" -and !$video) { # Get all video URLs in a YouTube playlist
    $is_youtube_playlist = $true
}

if ($folder) {
    $template = "Media/$folder/%(uploader)s/%(title)s [%(id)s].%(ext)s"
} else {
    $template = "Media/%(uploader)s/%(title)s [%(id)s].%(ext)s"
}

$archive = Join-Path $tool_path $source "Archive_$source.txt"
$output_path = Join-Path $tool_path $source
# $log_name = "$date`_$source`_$folder".TrimEnd('_') + ".log"
# $log_path = Join-Path $tool_path $source "Logs" $log_name

if ($is_youtube_playlist) {
    $playlist_name = "$date`_$source`_$folder".TrimEnd('_') + ".ini"
    $playlist_path = Join-Path $tool_path $source "Links" $playlist_name
     if (Test-Path $playlist_path) {
        Remove-Item $playlist_path -verbose
    }
    $clean_url = Get-CleanURL -url $url
} else {
    $clean_url = Get-CleanURL -url $url -youtube_param "v"
}

$ip = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json'
$ver = yt-dlp --ignore-config --version
$update_msg = yt-dlp --ignore-config --update-to nightly

Write-Output "Public IP address: $($ip.ip)"
write-output ""
write-output "Current version: $ver"
write-output $update_msg
write-output ""
Write-Output "Media source: $source [$url]"
Write-Output "Archive: $archive"
Write-Output "Output Path: $output_path"
Write-Output "Template: $template"
Write-Output "Playlist: $playlist_path"
Write-Output "Write metadata?: $write_metadata"
Write-Output "Clean URL: $clean_url"
Write-Output ""

$url = $clean_url

if ($write_metadata) { # Download Twitter videos
    yt-dlp --download-archive $archive --ffmpeg-location $ffmpeg_path -P $output_path -o $template --write-description --write-info-json --write-thumbnail $url
} elseif ($playlist_path) {  # Download YouTube Playlist
    yt-dlp --ignore-config --flat-playlist -i --print-to-file url $playlist_path $clean_url
    yt-dlp --download-archive $archive --ffmpeg-location $ffmpeg_path -P $output_path -o $template --batch-file $playlist_path
} else { # Download single YouTube video
    yt-dlp --download-archive $archive --ffmpeg-location $ffmpeg_path -P $output_path -o $template $url
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output ""
$msg = "{0}: DONE." -f $timestamp
Write-Output $msg
Write-Output ""
