param(
    [string] $Silent,
    [string] $NetworkPath
  )

$CacheExe = "$NetworkPath\pc-client-local-cache.exe"

$LocalPath = $env:LOCALAPPDATA + "\temp"

$papercut = Get-Process pc-client -ErrorAction SilentlyContinue
if (!$papercut) {
    if ($Silent -eq $true){
        Start-Process -FilePath $CacheExe -ArgumentList "--silent","--noquit","--cache $LocalPath"
        }
    else{
        Start-Process -FilePath $CacheExe -ArgumentList "--noquit","--cache $LocalPath"
        }
}

Remove-Variable papercut
