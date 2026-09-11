[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
. (Join-Path $repo 'lib\ConversionCore.ps1')

$script:passed = 0
function Assert-Equal([object]$Actual, [object]$Expected, [string]$Name) {
    if ([string]$Actual -ne [string]$Expected) {
        throw "${Name}: expected [$Expected], got [$Actual]"
    }
    $script:passed++
}

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw "${Name}: condition was false" }
    $script:passed++
}

$routeCases = @(
    @('1.20.1','forge','forge-1.20.1'),
    @('1.20.4','forge','forge-1.20.2-1.20.4'),
    @('1.21.8','neoforge','neoforge-1.21.x'),
    @('24.1.2','neoforge','neoforge-22-to-25'),
    @('26.1.0.9','neoforge','neoforge-26.0-26.1'),
    @('26.2.0.72','neoforge','already-26.2'),
    @('1.21.8','fabric','unsupported-fabric-quilt')
)
Assert-Equal (ConvertTo-NormalizedMinecraftVersion 'neoforge-26.2.0.72') '26.2.0.72' 'four-part NeoForge version normalization'
Assert-Equal (ConvertTo-NormalizedMinecraftVersion '[26.1.0.9,26.2)') '26.1.0.9' 'four-part NeoForge range normalization'
foreach ($case in $routeCases) {
    Assert-Equal (Get-MigrationRoute -SourceVersion $case[0] -Loader $case[1]) $case[2] "route $($case[0])"
}

$primerCases = @(
    @('1.20.1',16,'1.20.1'), @('1.20.2',16,'1.20.1'), @('1.20.3',16,'1.20.1'), @('1.20.4',15,'1.20.4'),
    @('1.20.5',14,'1.20.5'), @('1.20.6',13,'1.20.6'), @('1.21.0',12,'1.21'), @('1.21.1',11,'1.21.1'),
    @('1.21.2',10,'1.21.2/3'), @('1.21.3',10,'1.21.2/3'), @('1.21.4',9,'1.21.4'), @('1.21.5',8,'1.21.5'),
    @('1.21.6',7,'1.21.6'), @('1.21.7',6,'1.21.7'), @('1.21.8',5,'1.21.8'), @('1.21.9',4,'1.21.9'),
    @('1.21.10',3,'1.21.10'), @('1.21.11',2,'1.21.11'), @('22.0.1',1,'26.1'), @('25.3.4',1,'26.1'),
    @('26.0.0.7',1,'26.1'), @('26.1.2',1,'26.1'), @('26.2',0,''), @('26.2.0.72',0,''), @('unknown',0,'')
)
foreach ($case in $primerCases) {
    $chain = @(Get-PrimerMigrationChain -SourceVersion $case[0])
    Assert-Equal $chain.Count $case[1] "primer count $($case[0])"
    $first = if ($chain.Count) { [string]$chain[0].from } else { '' }
    Assert-Equal $first $case[2] "primer start $($case[0])"
}

$forge1204Passes = @(Get-RecommendedMigrationPasses -Route 'forge-1.20.2-1.20.4')
Assert-True ($forge1204Passes -notcontains 'srg-1.20.1') 'Forge 1.20.4 skips 1.20.1 SRG map'
Assert-True ($forge1204Passes -contains 'neoforge-26-api') 'Forge 1.20.4 receives 26.2 API pass'

$fixture = Join-Path ([IO.Path]::GetTempPath()) ('legacy-converter-test-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $fixture 'src\main\java\example') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $fixture 'gradle.properties') -Value "minecraft_version=1.20.4`nforge_version=49.0.50"
    Set-Content -LiteralPath (Join-Path $fixture 'src\main\java\example\Example.java') -Value 'import net.minecraftforge.eventbus.api.SubscribeEvent; class Example {}'
    $profile = Get-SourceProfile -Root $fixture
    Assert-Equal $profile.SourceVersion '1.20.4' 'Forge 1.20.4 fixture version detection'
    Assert-Equal $profile.Loader 'forge' 'Forge 1.20.4 fixture loader detection'
    Assert-Equal $profile.Route 'forge-1.20.2-1.20.4' 'Forge 1.20.4 fixture route'
    Assert-True (@($profile.RecommendedPasses) -notcontains 'srg-1.20.1') 'Forge 1.20.4 fixture skips SRG pass'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

$sample = 'BLOCKS.register(name, block)'
Assert-Equal (Convert-CustomBlockRegistrationText $sample) $sample 'unmatched block helper unchanged'

foreach ($file in Get-ChildItem -LiteralPath $repo -Recurse -Filter '*.ps1' -File) {
    $tokens = $null
    $errors = $null
    [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    Assert-Equal @($errors).Count 0 "PowerShell parse $($file.Name)"
}

foreach ($file in @('Convert-Forge1201-ToNeoForge262.ps1','Convert-JarToProject.ps1','Convert-OldJarToNeoForge262.ps1','lib\ModDependencyPipeline.ps1')) {
    $text = Get-Content -LiteralPath (Join-Path $repo $file) -Raw
    Assert-True ($text -match "26\.2\.0\.72") "26.2.0.72 default in $file"
    Assert-True ($text -notmatch "26\.2\.0\.66") "stale 26.2.0.66 absent from $file"
}

Write-Host "Regression tests passed: $script:passed" -ForegroundColor Green
