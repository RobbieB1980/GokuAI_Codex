<#
.SYNOPSIS
  Build portable package + Windows installer for RMCodexMCConverter.

.DESCRIPTION
  Produces:
    dist/portable/RMCodexMCConverter/
    dist/RMCodexMCConverter-Portable.zip
    dist/portable-payload.zip
    dist/RMCodexMCConverter-Setup.exe

.EXAMPLE
  .\scripts\Build-Release.ps1
#>
[CmdletBinding()]
param(
    [string]$Configuration = 'Release',
    [string]$Runtime = 'win-x64'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$Dist = Join-Path $RepoRoot 'dist'
$PortableRoot = Join-Path $Dist 'portable\RMCodexMCConverter'
$GuiProj = Join-Path $RepoRoot 'src\RB.LegacyJavaConverter\RB.LegacyJavaConverter.csproj'
$SetupProj = Join-Path $RepoRoot 'src\RB.LegacyJavaConverter.Setup\RB.LegacyJavaConverter.Setup.csproj'

function Remove-TreeLongPath([string]$Target) {
    $resolvedTarget = [IO.Path]::GetFullPath($Target)
    $resolvedRepo = [IO.Path]::GetFullPath([string]$RepoRoot).TrimEnd('\') + '\'
    if (-not $resolvedTarget.StartsWith($resolvedRepo, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove path outside repository: $resolvedTarget"
    }
    if ([IO.Directory]::Exists($resolvedTarget)) {
        [IO.Directory]::Delete('\\?\' + $resolvedTarget, $true)
    }
}

Write-Host "==> Cleaning dist" -ForegroundColor Cyan
if (Test-Path $Dist) { Remove-TreeLongPath $Dist }
New-Item -ItemType Directory -Path $PortableRoot -Force | Out-Null

Write-Host "==> Publishing GUI (self-contained $Runtime)" -ForegroundColor Cyan
$guiOut = Join-Path $Dist 'publish-gui'
dotnet publish $GuiProj `
    -c $Configuration `
    -r $Runtime `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -p:DebugType=None `
    -p:DebugSymbols=false `
    -o $guiOut

if ($LASTEXITCODE -ne 0) { throw "GUI publish failed" }

Write-Host "==> Assembling portable folder" -ForegroundColor Cyan
$guiExe = Join-Path $guiOut 'RMCodexMCConverter.exe'
if (-not (Test-Path $guiExe)) { throw "GUI publish missing RMCodexMCConverter.exe" }
Copy-Item $guiExe $PortableRoot -Force

$toolsSrc = Join-Path $guiOut 'tools'
if (Test-Path $toolsSrc) {
    Copy-Item $toolsSrc (Join-Path $PortableRoot 'tools') -Recurse -Force
}
else {
    New-Item -ItemType Directory -Path (Join-Path $PortableRoot 'tools') -Force | Out-Null
    Copy-Item (Join-Path $RepoRoot 'Convert-Forge1201-ToNeoForge262.ps1') (Join-Path $PortableRoot 'tools') -Force
    Copy-Item (Join-Path $RepoRoot 'Convert-JarToProject.ps1') (Join-Path $PortableRoot 'tools') -Force
    Copy-Item (Join-Path $RepoRoot 'Convert-OldJarToNeoForge262.ps1') (Join-Path $PortableRoot 'tools') -Force
    Copy-Item (Join-Path $RepoRoot 'README.md') (Join-Path $PortableRoot 'tools') -Force
    if (Test-Path (Join-Path $RepoRoot 'docs')) {
        Copy-Item (Join-Path $RepoRoot 'docs') (Join-Path $PortableRoot 'tools\docs') -Recurse -Force
    }
    if (Test-Path (Join-Path $RepoRoot 'LICENSE')) {
        Copy-Item (Join-Path $RepoRoot 'LICENSE') (Join-Path $PortableRoot 'tools') -Force
    }
}
# Always overwrite tools scripts from repo root (publish output can ship stale copies)
$toolsFinal = Join-Path $PortableRoot 'tools'
if (-not (Test-Path $toolsFinal)) { New-Item -ItemType Directory -Path $toolsFinal -Force | Out-Null }
foreach ($s in @('Convert-JarToProject.ps1','Convert-OldJarToNeoForge262.ps1','Convert-Forge1201-ToNeoForge262.ps1','Open-CodexRepairSession.ps1','Open-KATRepairSession.ps1','Prepare-RepairTriage.ps1','Watch-KATRepairSession.ps1','Watch-CodexGuidance.ps1','Build-WithDestinationJava.ps1','Lint-MigrationSkills.ps1','README.md','LICENSE','CHANGELOG.md')) {
    $src = Join-Path $RepoRoot $s
    if (Test-Path $src) {
        Copy-Item $src $toolsFinal -Force
        Write-Host "    tools/$s (from repo)"
    }
}
if (Test-Path (Join-Path $RepoRoot 'docs')) {
    $docsDest = Join-Path $toolsFinal 'docs'
    if (Test-Path $docsDest) { Remove-Item $docsDest -Recurse -Force }
    Copy-Item (Join-Path $RepoRoot 'docs') $docsDest -Recurse -Force
}
$libSrc = Join-Path $RepoRoot 'lib'
if (Test-Path $libSrc) {
    $libDest = Join-Path $toolsFinal 'lib'
    if (Test-Path $libDest) { Remove-TreeLongPath $libDest }
    New-Item -ItemType Directory -Path $libDest -Force | Out-Null
    # Copy-Item fails at MAX_PATH for the nested solved-conversion overlays.
    # Robocopy is long-path aware and preserves the complete portable toolset.
    & robocopy.exe $libSrc $libDest /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "tools/lib copy failed (robocopy exit $LASTEXITCODE)" }
    Write-Host "    tools/lib (SRG map + dependency catalog)"
}

@'
@echo off
cd /d "%~dp0"
start "" "%~dp0RMCodexMCConverter.exe"
'@ | Set-Content (Join-Path $PortableRoot 'Start-Converter.bat') -Encoding ASCII

Copy-Item (Join-Path $RepoRoot 'README.md') (Join-Path $PortableRoot 'README.md') -Force
if (Test-Path (Join-Path $RepoRoot 'LICENSE')) {
    Copy-Item (Join-Path $RepoRoot 'LICENSE') (Join-Path $PortableRoot 'LICENSE.txt') -Force
}
$ico = Join-Path $RepoRoot 'assets\app.ico'
if (Test-Path $ico) {
    Copy-Item $ico (Join-Path $PortableRoot 'app.ico') -Force
    Write-Host "    app.ico (from assets)"
}

$versionFile = Join-Path $RepoRoot 'version.txt'
if (-not (Test-Path $versionFile)) {
    # Fall back to GUI csproj Version when version.txt is absent.
    $guiCsproj = Join-Path $RepoRoot 'src\RB.LegacyJavaConverter\RB.LegacyJavaConverter.csproj'
    $ver = '2.10.5'
    if (Test-Path $guiCsproj) {
        $m = Select-String -Path $guiCsproj -Pattern '<Version>([^<]+)</Version>' | Select-Object -First 1
        if ($m) { $ver = $m.Matches[0].Groups[1].Value }
    }
    Set-Content -LiteralPath $versionFile -Value $ver -Encoding ascii
}
Copy-Item $versionFile (Join-Path $PortableRoot 'version.txt') -Force
Write-Host "    version.txt = $((Get-Content -LiteralPath (Join-Path $PortableRoot 'version.txt') -Raw).Trim())"

Write-Host "==> Creating portable ZIP" -ForegroundColor Cyan
$portableZip = Join-Path $Dist 'RMCodexMCConverter-Portable.zip'
if (Test-Path $portableZip) { Remove-Item $portableZip -Force }
# Compress-Archive enumerates through legacy MAX_PATH APIs. Windows bsdtar is
# long-path aware and retains the deeply nested semantic overlay sources.
& tar.exe -a -c -f $portableZip -C (Join-Path $Dist 'portable') 'RMCodexMCConverter'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $portableZip)) { throw 'Portable ZIP creation failed' }

$payloadZip = Join-Path $Dist 'portable-payload.zip'
Copy-Item $portableZip $payloadZip -Force

Write-Host "==> Publishing Setup installer (self-contained $Runtime, payload embedded)" -ForegroundColor Cyan
$setupOut = Join-Path $Dist 'publish-setup'
if (-not (Test-Path $payloadZip)) { throw "portable-payload.zip missing before setup publish" }

dotnet publish $SetupProj `
    -c $Configuration `
    -r $Runtime `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -p:DebugType=None `
    -p:DebugSymbols=false `
    -o $setupOut

if ($LASTEXITCODE -ne 0) { throw "Setup publish failed" }

$setupExe = Join-Path $setupOut 'RMCodexMCConverter-Setup.exe'
if (-not (Test-Path -LiteralPath $setupExe)) {
    throw "Setup publish succeeded but EXE not found: $setupExe"
}

Copy-Item $setupExe $Dist -Force
Copy-Item $setupExe (Join-Path $Dist 'publish-setup\RMCodexMCConverter-Setup.exe') -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Build complete:" -ForegroundColor Green
Write-Host "  Portable folder : $PortableRoot"
Write-Host "  Portable ZIP    : $portableZip"
Write-Host "  Setup EXE       : $(Join-Path $Dist 'RMCodexMCConverter-Setup.exe')"
Write-Host ""
Get-ChildItem $Dist -File | Format-Table Name, @{N='MB';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime

# Keep Repair-in-Codex workspace skills/agents in sync on this machine
$sync = Join-Path $PSScriptRoot 'Sync-GokuaiConverterWorkspace.ps1'
if (Test-Path -LiteralPath $sync) {
    Write-Host "==> Syncing GokuAI Repair-in-Codex workspace overlay" -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $sync -RepoRoot $RepoRoot
}
