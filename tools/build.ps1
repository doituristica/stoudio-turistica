# Runs the whole pipeline in the right order.
#
#   .\tools\build.ps1                       rebuild from cached data
#   .\tools\build.ps1 -Refresh              re-pull from Airtable first (also grabs new images)
#   .\tools\build.ps1 -BaseUrl https://...  set the domain used in sitemap.xml
#
# Order matters: data -> images (patches the JSON and writes the list index) ->
# fonts (subsets against the finished pages and JSON) -> sitemap.
param(
  [switch]$Refresh,
  [string]$BaseUrl = 'https://stoudio.turistica.si'
)

$ErrorActionPreference = 'Stop'
$t0 = Get-Date

Write-Host '== data =============================================='
if ($Refresh) { & "$PSScriptRoot\build-data.ps1" -Refresh } else { & "$PSScriptRoot\build-data.ps1" }

Write-Host '== images ============================================'
& "$PSScriptRoot\optimize-images.ps1"

Write-Host '== fonts ============================================='
& "$PSScriptRoot\fetch-fonts.ps1"

Write-Host '== sitemap ==========================================='
& "$PSScriptRoot\build-sitemap.ps1" -BaseUrl $BaseUrl

$site = Join-Path (Split-Path $PSScriptRoot -Parent) 'site'
$files = Get-ChildItem $site -Recurse -File
Write-Host ''
"DONE in {0:N0}s  |  site\: {1} files, {2:N1} MB" -f `
  ((Get-Date) - $t0).TotalSeconds, $files.Count, (($files | Measure-Object Length -Sum).Sum/1MB)
