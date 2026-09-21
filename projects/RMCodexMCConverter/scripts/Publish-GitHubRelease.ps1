<#
.SYNOPSIS
  Create/update a GitHub Release and upload portable + setup artifacts from dist/.

.EXAMPLE
  .\scripts\Publish-GitHubRelease.ps1
#>
[CmdletBinding()]
param(
    [string]$Tag = '',
    [string]$Repo = 'RobbieB1980/LegacyJavaConverter',
    [string]$Name = ''
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$Dist = Join-Path $RepoRoot 'dist'
. (Join-Path $RepoRoot 'lib\ReleaseMetadata.ps1')
$identity = Get-ReleaseIdentity -VersionPropsPath (Join-Path $RepoRoot 'eng\Version.props')
if ([string]::IsNullOrWhiteSpace($Tag)) { $Tag = $identity.Tag }
if ([string]::IsNullOrWhiteSpace($Name)) { $Name = $identity.Name }

$setup = Join-Path $Dist 'RB-Legacy-Java-Converter-Setup.exe'
$portable = Join-Path $Dist 'RB-Legacy-Java-Converter-Portable.zip'
if (-not (Test-Path $setup)) { throw "Missing setup EXE in dist/ - run Build-Release.ps1 first" }
if (-not (Test-Path $portable)) { throw "Missing portable ZIP in dist/ - run Build-Release.ps1 first" }

$fill = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
$token = ($fill | Where-Object { $_ -like 'password=*' }) -replace '^password=', ''
if (-not $token) { throw 'Could not obtain GitHub credentials from git credential helper.' }

$headers = @{
    Authorization          = "Bearer $token"
    Accept                 = 'application/vnd.github+json'
    'User-Agent'           = 'RB-Legacy-Java-Converter-Release'
    'X-GitHub-Api-Version' = '2022-11-28'
}

$api = "https://api.github.com/repos/$Repo"

function ConvertTo-JsonUtf8([hashtable]$Object) {
    Add-Type -AssemblyName System.Web.Extensions -ErrorAction SilentlyContinue
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $ser.MaxJsonLength = [int]::MaxValue
    return $ser.Serialize($Object)
}

function Invoke-GitHubJson([string]$Method, [string]$Uri, [hashtable]$BodyObj = $null) {
    $params = @{
        Headers = $headers
        Uri     = $Uri
        Method  = $Method
    }
    if ($null -ne $BodyObj) {
        $json = ConvertTo-JsonUtf8 $BodyObj
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $params['Body'] = $bytes
        $params['ContentType'] = 'application/json; charset=utf-8'
    }
    return Invoke-RestMethod @params
}

$notes = @"
## RB Legacy Java Converter $Tag

Converts **Forge/NeoForge 1.20.1Ã¢â‚¬â€œ26.1** (and decompiled jars) Ã¢â€ â€™ **NeoForge 26.2** (default **26.2.0.72**).

### Downloads

| File | Description |
|------|-------------|
| ``RB-Legacy-Java-Converter-Setup.exe`` | Windows installer (self-contained; **embeds** portable toolset only) |
| ``RB-Legacy-Java-Converter-Portable.zip`` | No install Ã¢â‚¬â€ extract and run ``Start-Converter.bat`` or the EXE |

### What's new in $($identity.Version)

- vNext foundation with reproducible release contents and staged validation contracts
- JavaParser analysis worker and PowerShell bridge in shadow mode
- Hardened NeoForge 26.2 transforms, golden fixtures, and conversion-manifest schema
- Repair with GokuCodexAI opens native Codex with the versioned vNext skill,
  local knowledge MCP, bounded evidence, and optional KAT/Qwen workers

### Requirements

- Windows x64
- PowerShell 5.1+
- JDK 25 for compile/build of converted projects (destination Java)
- GokuCodexAI at ``C:\GokuCodexAI`` and an authenticated Codex installation for assisted repair

### Notes

- Original input is never modified (always writes to output folder).
- Setup installs under ``%LOCALAPPDATA%\RB-Legacy-Java-Converter`` by default (no admin required).
- Detect source version -> primer path -> solved overlays/passes -> destination-Java ``gradlew build`` for installable jars.
- Build success and runtime/content/behaviour validation are reported separately.
- Prefer official 26.2 mod jars when published; converter path is for when they are absent.
"@

Write-Host "==> Checking for existing release $Tag" -ForegroundColor Cyan
$release = $null
try {
    $release = Invoke-GitHubJson -Method Get -Uri "$api/releases/tags/$Tag"
    Write-Host "    Release exists (id $($release.id)) - will refresh assets and notes"
    $release = Invoke-GitHubJson -Method Patch -Uri "$api/releases/$($release.id)" -BodyObj @{
        name       = $Name
        body       = $notes
        draft      = $false
        prerelease = $false
    }
}
catch {
    Write-Host "    Creating release $Tag"
    $release = Invoke-GitHubJson -Method Post -Uri "$api/releases" -BodyObj @{
        tag_name   = $Tag
        name       = $Name
        body       = $notes
        draft      = $false
        prerelease = $false
    }
}

function Upload-Asset([string]$FilePath) {
    $name = [IO.Path]::GetFileName($FilePath)
    $release = Invoke-GitHubJson -Method Get -Uri "$api/releases/tags/$Tag"
    if ($release.assets) {
        $existing = $release.assets | Where-Object { $_.name -eq $name }
        foreach ($a in @($existing)) {
            Write-Host "    Deleting existing asset $name"
            Invoke-RestMethod -Headers $headers -Uri "$api/releases/assets/$($a.id)" -Method Delete | Out-Null
        }
        $release = Invoke-GitHubJson -Method Get -Uri "$api/releases/tags/$Tag"
    }
    $uploadUrl = $release.upload_url -replace '\{\?name,label\}', "?name=$([uri]::EscapeDataString($name))"
    Write-Host "    Uploading $name ($([math]::Round((Get-Item $FilePath).Length/1MB,1)) MB)..."
    $bytes = [IO.File]::ReadAllBytes($FilePath)
    $ctype = if ($name.EndsWith('.zip')) { 'application/zip' } else { 'application/octet-stream' }
    $uploadHeaders = @{
        Authorization          = "Bearer $token"
        Accept                 = 'application/vnd.github+json'
        'User-Agent'           = 'RB-Legacy-Java-Converter-Release'
        'X-GitHub-Api-Version' = '2022-11-28'
        'Content-Type'         = $ctype
    }
    $wc = New-Object System.Net.WebClient
    foreach ($k in $uploadHeaders.Keys) { $wc.Headers[$k] = $uploadHeaders[$k] }
    try {
        [void]$wc.UploadData($uploadUrl, 'POST', $bytes)
    }
    finally {
        $wc.Dispose()
    }
    Write-Host "    Uploaded $name" -ForegroundColor Green
}

Upload-Asset $setup
Upload-Asset $portable

Write-Host ""
Write-Host "Published: https://github.com/$Repo/releases/tag/$Tag" -ForegroundColor Green

