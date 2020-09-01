# UNC path to your Papercut Server Cache
$Cache = "YourUNCpath\pc-client-local-cache.exe"

# Appdata Location to avoid NTFS perms on C:
$user = $env:username
$path = "C:\Users\$user\AppData\Local\Temp"

# Check if running, if not then run
$papercut = Get-Process pc-client -ErrorAction SilentlyContinue
if (!$papercut) {
    Start-Process -FilePath $cache -ArgumentList "--silent","--noquit","--cache $path"
}

# Cleanup
Remove-Variable papercut
