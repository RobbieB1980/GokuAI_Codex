[CmdletBinding()]
param([ValidateSet('Release','Debug')][string]$Configuration = 'Release', [string]$Runtime = 'win-x64')
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dist = Join-Path $repo 'dist\rb-26.2-to-26.3'
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Path $dist | Out-Null
$project = Join-Path $repo 'src\RB.RB262To263Converter\RB.RB262To263Converter.csproj'
dotnet publish $project -c $Configuration -r $Runtime --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o (Join-Path $dist 'app')
if ($LASTEXITCODE -ne 0) { throw 'Preview GUI publish failed.' }
Copy-Item (Join-Path $repo 'targets\rb-26.2-to-26.3\README.md') (Join-Path $dist 'README.md')
Copy-Item (Join-Path $repo 'targets\rb-26.2-to-26.3\target-manifest.json') (Join-Path $dist 'target-manifest.json')
Copy-Item (Join-Path $repo 'targets\rb-26.2-to-26.3\CHANGELOG.md') (Join-Path $dist 'CHANGELOG.md')
$zip = Join-Path $repo 'dist\RB-26.2-to-26.3-Converter-Preview.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $dist '*') -DestinationPath $zip -CompressionLevel Optimal
Write-Host "Preview package: $zip" -ForegroundColor Green
