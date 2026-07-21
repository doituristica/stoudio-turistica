# Converts raw Airtable/Softr JSON into a clean activities.json and downloads all images locally.
# ASCII-only source on purpose (Windows PowerShell 5.1 reads .ps1 as ANSI without a BOM).
#
#   .\tools\build-data.ps1            rebuild from the cached data\raw_arhiv.json
#   .\tools\build-data.ps1 -Refresh   re-pull the records from Airtable first
#
# Airtable attachment URLs are signed and expire after ~a day, so -Refresh must be
# followed immediately by the image download (which this script does in one pass).
param([switch]$Refresh)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$raw  = Join-Path $root 'data\raw_arhiv.json'
$rawPrivate = Join-Path $root 'data\raw_arhiv.private.json'

if ($Refresh) {
  $endpoint = 'https://stoudio.turistica.si/v1/datasource/airtable/31aa11c9-4bd7-4f25-94f6-3bd4dc34042d/43298a67-9bbf-4cc2-afaf-a7ea66506cc4/c400dfdf-53b4-43ec-8459-8e3c175bab02/6e8553d5-9af6-4843-b0f1-b3360f7bd02d/data'
  New-Item -ItemType Directory -Force -Path (Split-Path $raw -Parent) | Out-Null
  Write-Host 'Fetching records from Airtable...'
  Invoke-WebRequest -Uri $endpoint -Method Post -ContentType 'application/json' -Body '{}' `
    -Headers @{ 'Referer' = 'https://stoudio.turistica.si/arhiv' } `
    -OutFile $rawPrivate -UseBasicParsing -TimeoutSec 120

  # Airtable vrne za vsakega sodelujocega tudi e-naslov. Ti nikjer niso potrebni,
  # zato jih iz objavljene kopije odstranimo - polna ostane samo lokalno v
  # raw_arhiv.private.json, ki ga .gitignore drzi izven repozitorija.
  $text = [System.IO.File]::ReadAllText($rawPrivate, [System.Text.Encoding]::UTF8)
  $text = [regex]::Replace($text, '"email"\s*:\s*"[^"]*"\s*,\s*', '')
  $text = [regex]::Replace($text, '\s*,\s*"email"\s*:\s*"[^"]*"', '')
  [System.IO.File]::WriteAllText($raw, $text, (New-Object System.Text.UTF8Encoding($false)))

  $left = ([regex]::Matches($text, '[\w.\-+]+@[\w.\-]+\.\w+')).Count
  if ($left) { Write-Warning "raw_arhiv.json se vsebuje $left e-naslovov - preveri pred objavo!" }
}
$site = Join-Path $root 'site'
$imgDir = Join-Path $site 'assets\img'
New-Item -ItemType Directory -Force -Path $imgDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $site 'data') | Out-Null

$d = Get-Content $raw -Raw -Encoding utf8 | ConvertFrom-Json

$typeMap = @{
  'sTOUdio TALK'    = @{ slug='pogovori';  label='Pogovor';  labelEn='Talk' }
  'sTOUdio DATE'    = @{ slug='zmenki';    label='Zmenek';   labelEn='Date' }
  'sTOUdio TRIP'    = @{ slug='izleti';    label='Izlet';    labelEn='Trip' }
  'sTOUdio PROJECT' = @{ slug='projekti';  label='Projekt';  labelEn='Project' }
  'sTOUdio WEEKEND' = @{ slug='vikendi';   label='Vikend';   labelEn='Weekend' }
  'sTOUdio STARTUP' = @{ slug='startaupi'; label='Startup';  labelEn='Startup' }
}

# c-caron, c-acute, s-caron, z-caron, d-stroke -> ascii
$dia = @{ ([char]0x010D)='c'; ([char]0x0107)='c'; ([char]0x0161)='s'; ([char]0x017E)='z'; ([char]0x0111)='d' }

function Get-Slug([string]$s) {
  $t = $s.Trim().ToLowerInvariant()
  foreach ($k in $dia.Keys) { $t = $t.Replace([string]$k, $dia[$k]) }
  $t = $t -replace '[^a-z0-9]+','-'
  $t.Trim('-')
}

function Get-Names($v) {
  @($v) | Where-Object { $_ -and $_.name } | ForEach-Object { [string]$_.name }
}

$out = New-Object System.Collections.ArrayList
$dl = 0; $skip = 0; $fail = 0

foreach ($r in $d.records) {
  $f = $r.fields
  $type = [string]$f.'Type of activity'
  $m = $typeMap[$type]
  if (-not $m) { $m = @{ slug='ostalo'; label='Aktivnost'; labelEn='Activity' } }

  $recDir = Join-Path $imgDir $r.id
  $images = New-Object System.Collections.ArrayList
  $i = 0
  foreach ($a in @($f.Attachments)) {
    if (-not $a -or -not $a.url) { continue }
    $i++
    # Attachments are not all images - at least one record holds an .mp4 whose
    # Airtable filename still ends in .jpg, so trust the MIME type, not the name.
    $mime = [string]$a.type
    $kind = if ($mime -like 'video/*') { 'video' } else { 'image' }
    $ext = switch -Regex ($mime) {
      'png'   { '.png';  break }
      'webp'  { '.webp'; break }
      'gif'   { '.gif';  break }
      'mp4'   { '.mp4';  break }
      'quicktime' { '.mov'; break }
      'webm'  { '.webm'; break }
      default { '.jpg' }
    }
    $stem = '{0:d2}' -f $i
    $name = "$stem$ext"
    $dest = Join-Path $recDir $name

    # optimize-images.ps1 rewrites .png sources as .jpg, so an attachment that is
    # already on disk may carry a different extension than the MIME type suggests.
    # Match on the stem or we would re-download every converted file on each build.
    $existing = $null
    if (Test-Path $recDir) {
      $existing = Get-ChildItem $recDir -File | Where-Object {
        [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -eq $stem
      } | Select-Object -First 1
    }

    if ($existing) {
      $name = $existing.Name
      $skip++
    } else {
      New-Item -ItemType Directory -Force -Path $recDir | Out-Null
      # prefer the 'large' rendition for oversized originals - smaller files, plenty for web
      $src = [string]$a.url
      if ($a.thumbnails.large.url -and [int]$a.width -gt 1400) { $src = [string]$a.thumbnails.large.url }
      try {
        Invoke-WebRequest -Uri $src -OutFile $dest -TimeoutSec 90 -UseBasicParsing
        $dl++
      } catch {
        Write-Warning "FAIL $($r.id) $name : $($_.Exception.Message)"
        $fail++
        continue
      }
    }
    $entry = [ordered]@{
      src  = "assets/img/$($r.id)/$name"
      kind = $kind
    }
    if ($a.width)  { $entry.w = [int]$a.width }
    if ($a.height) { $entry.h = [int]$a.height }
    [void]$images.Add($entry)
  }

  [void]$out.Add([ordered]@{
    id         = $r.id
    slug       = (Get-Slug ([string]$f.Activity))
    title      = ([string]$f.Activity).Trim()
    type       = $type
    category   = $m.slug
    catLabel   = $m.label
    catLabelEn = $m.labelEn
    start      = [string]$f.Start
    finish     = [string]$f.Finish
    lead       = ([string]$f.'Single line text').Trim()
    leadEn     = ([string]$f.'Single line ENG').Trim()
    body       = ([string]$f.Description).Trim()
    organizers = @(Get-Names $f.'Organizers of the event')
    authors    = @(Get-Names $f.'Text prepared by')
    images     = @($images)
  })
}

# newest first
$sorted = @($out | Sort-Object -Property @{ Expression = { $_.start } } -Descending)

$json = $sorted | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path $site 'data\activities.json'), $json, (New-Object System.Text.UTF8Encoding($false)))

"OK  activities: $($sorted.Count)  | downloaded: $dl  skipped: $skip  failed: $fail"
