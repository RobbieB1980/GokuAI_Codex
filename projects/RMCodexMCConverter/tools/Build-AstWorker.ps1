<#
.SYNOPSIS
  Builds and tests the JavaParser AST worker distribution with destination Java.
#>
[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$CorePath = Join-Path $RepoRoot 'lib\ConversionCore.ps1'
$WorkerRoot = Join-Path $PSScriptRoot 'ast-worker'
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot 'lib\ast-worker'
}
$OutputPath = [IO.Path]::GetFullPath($OutputPath)
$generatedRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'lib')).TrimEnd('\')
$generatedPrefix = $generatedRoot + '\'
if (-not $OutputPath.StartsWith($generatedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "AST worker output must be below ${generatedRoot}: $OutputPath"
}

. $CorePath
$java = Resolve-Java -MinimumMajor 25 -ForTool 'JavaParser AST worker'
$javaHome = Get-JavaHomeFromJavaExe -JavaExePath $java.Path
$previousJavaHome = $env:JAVA_HOME
$previousPath = $env:Path

try {
    $env:JAVA_HOME = $javaHome
    $env:Path = (Join-Path $javaHome 'bin') + ';' + $previousPath
    Write-Host "==> Building AST worker with Java $($java.Major): $($java.Path)" -ForegroundColor Cyan
    & (Join-Path $WorkerRoot 'gradlew.bat') -p $WorkerRoot clean test installDist --no-daemon
    if ($LASTEXITCODE -ne 0) { throw "AST worker Gradle build failed (exit $LASTEXITCODE)" }
} finally {
    $env:JAVA_HOME = $previousJavaHome
    $env:Path = $previousPath
}

$distribution = Join-Path $WorkerRoot 'build\install\legacy-java-ast-worker'
if (-not (Test-Path -LiteralPath $distribution -PathType Container)) {
    throw "AST worker distribution was not created: $distribution"
}
if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
Copy-Item -Path (Join-Path $distribution '*') -Destination $OutputPath -Recurse -Force
Write-Host "AST worker distribution: $OutputPath" -ForegroundColor Green
