[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [Parameter(Mandatory=$true)][string]$Symbol,
    [string]$NeoVersion='26.2.0.72',
    [switch]$ReadFirst
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$project=(Resolve-Path -LiteralPath $ProjectRoot).Path
$candidates=@()
$artifactRoot=Join-Path $project 'build\moddev\artifacts'
if(Test-Path -LiteralPath $artifactRoot){$candidates+=@(Get-ChildItem -LiteralPath $artifactRoot -File -Filter '*-sources.jar' -ErrorAction SilentlyContinue)}
$neoCache=Join-Path $env:USERPROFILE ".gradle\caches\modules-2\files-2.1\net.neoforged\neoforge\$NeoVersion"
if(Test-Path -LiteralPath $neoCache){$candidates+=@(Get-ChildItem -LiteralPath $neoCache -Recurse -File -Filter "neoforge-$NeoVersion-sources.jar" -ErrorAction SilentlyContinue)}
$candidates=@($candidates|Sort-Object FullName -Unique)
if($candidates.Count -eq 0){throw 'No exact source JARs found. Run the destination Gradle build once, then retry.'}
$matches=New-Object Collections.Generic.List[object]
foreach($jar in $candidates){
    if(-not(Test-Path -LiteralPath $jar.FullName -PathType Leaf)){continue}
    foreach($entry in @(& tar.exe -tf $jar.FullName 2>$null | Where-Object {$_ -like "*$Symbol*"} | Select-Object -First 20)){
        $matches.Add([pscustomobject]@{Jar=$jar.FullName;Entry=[string]$entry})|Out-Null
    }
}
if($matches.Count -eq 0){Write-Output "No exact source entry matched '$Symbol'. Do not invent an API or cache path.";exit 3}
$matches|Format-Table -AutoSize
if($ReadFirst){& tar.exe -xOf $matches[0].Jar $matches[0].Entry}