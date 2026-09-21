[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
. (Join-Path $repo 'lib\ConversionCore.ps1')
. (Join-Path $repo 'lib\Minecraft262HardenedTransforms.ps1')

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
Assert-Equal (ConvertTo-NormalizedMinecraftVersion '26.2') '26.2' 'two-part target normalization'
Assert-Equal (ConvertTo-NormalizedMinecraftVersion 'minecraft 1.21.11') '1.21.11' 'three-part Minecraft normalization'
Assert-Equal (ConvertTo-NormalizedMinecraftVersion '126.2.0.72') '' 'embedded numeric token rejected'
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

$hardenedFixtures = Join-Path $repo 'tests\fixtures\hardened-262'
$leafInput = Get-Content (Join-Path $hardenedFixtures 'leaf-api\input.java') -Raw
$leafExpected = (Get-Content (Join-Path $hardenedFixtures 'leaf-api\expected.java') -Raw).TrimEnd()
$leafActual = Convert-Minecraft262LeafApiText -Text $leafInput
Assert-Equal $leafActual $leafExpected 'installed leaf API wave'
Assert-Equal (Convert-Minecraft262LeafApiText -Text $leafActual) $leafActual 'leaf API wave idempotence'

$treeInput = Get-Content (Join-Path $hardenedFixtures 'tree-feature\input.json') -Raw
$treeActual = Convert-Minecraft262TreeConfiguredFeatureDocument -JsonText $treeInput
$treeDocument = $treeActual | ConvertFrom-Json
Assert-Equal $treeDocument.type 'minecraft:tree' 'tree configured feature type preserved'
Assert-Equal $treeDocument.custom_flag 'preserve-me' 'tree configured feature unrelated property preserved'
Assert-Equal $treeDocument.config.below_trunk_provider.type 'minecraft:rule_based_state_provider' 'tree below-trunk provider created'
Assert-Equal $treeDocument.config.below_trunk_provider.rules[0].then.state.Name 'minecraft:podzol' 'tree dirt state preserved'
Assert-True ($null -eq $treeDocument.config.PSObject.Properties['dirt_provider']) 'legacy dirt provider removed'
Assert-True ($null -eq $treeDocument.config.PSObject.Properties['force_dirt']) 'legacy force_dirt removed'
Assert-Equal (Convert-Minecraft262TreeConfiguredFeatureDocument -JsonText $treeActual) $treeActual 'tree configured feature idempotence'

$clientItemInput = Get-Content (Join-Path $hardenedFixtures 'client-item\input.json') -Raw
$clientItemActual = Convert-Minecraft262ClientItemDocument -JsonText $clientItemInput -ModId 'example'
$clientItemDocument = $clientItemActual | ConvertFrom-Json
Assert-Equal $clientItemDocument.model.model 'example:item/template_spawn_egg' 'client item spawn egg migrated'
Assert-Equal $clientItemDocument.comment 'minecraft:item/template_spawn_egg' 'unrelated spawn egg string preserved'
Assert-Equal (Convert-Minecraft262ClientItemDocument -JsonText $clientItemActual -ModId 'example') $clientItemActual 'client item spawn egg idempotence'

$versionPropsPath = Join-Path $repo 'eng\Version.props'
$portableManifestPath = Join-Path $repo 'eng\portable-manifest.json'
$portableValidatorPath = Join-Path $repo 'scripts\Test-PortableManifest.ps1'
Assert-True (Test-Path -LiteralPath $versionPropsPath) 'shared version properties exist'
Assert-True (Test-Path -LiteralPath $portableManifestPath) 'portable manifest exists'
Assert-True (Test-Path -LiteralPath $portableValidatorPath) 'portable manifest validator exists'

[xml]$versionProps = Get-Content -LiteralPath $versionPropsPath -Raw
Assert-Equal $versionProps.Project.PropertyGroup.Version '3.0.0' 'shared product version'
Assert-Equal $versionProps.Project.PropertyGroup.FileVersion '3.0.0.0' 'shared file version'
Assert-Equal $versionProps.Project.PropertyGroup.InformationalVersion '3.0.0' 'shared informational version'
Assert-Equal $versionProps.Project.PropertyGroup.IncludeSourceRevisionInInformationalVersion 'false' 'product version excludes source revision suffix'
foreach ($projectPath in @('src\RB.LegacyJavaConverter\RB.LegacyJavaConverter.csproj', 'src\RB.LegacyJavaConverter.Setup\RB.LegacyJavaConverter.Setup.csproj')) {
    [xml]$project = Get-Content -LiteralPath (Join-Path $repo $projectPath) -Raw
    $versionImport = @($project.Project.Import | Where-Object { $_.Project -eq '..\..\eng\Version.props' })
    Assert-Equal $versionImport.Count 1 "shared version import $projectPath"
    Assert-True ($null -eq $project.Project.PropertyGroup.Version) "no literal product version $projectPath"
}
Assert-Equal ((Get-Content -LiteralPath (Join-Path $repo 'version.txt') -Raw).Trim()) '3.0.0' 'tracked version matches shared product version'

$releaseMetadataPath = Join-Path $repo 'lib\ReleaseMetadata.ps1'
Assert-True (Test-Path -LiteralPath $releaseMetadataPath) 'release metadata helper exists'
. $releaseMetadataPath
$releaseIdentity = Get-ReleaseIdentity -VersionPropsPath $versionPropsPath
Assert-Equal $releaseIdentity.Tag 'v3.0.0' 'release tag derives from shared product version'
Assert-Equal $releaseIdentity.Name 'RB Legacy Java Converter 3.0.0' 'release name derives from shared product version'
$mainFormText = Get-Content -LiteralPath (Join-Path $repo 'src\RB.LegacyJavaConverter\MainForm.cs') -Raw
$setupFormText = Get-Content -LiteralPath (Join-Path $repo 'src\RB.LegacyJavaConverter.Setup\SetupForm.cs') -Raw
Assert-True ($mainFormText -match '\?\? "3\.0\.0"') 'GUI fallback version is 3.0.0'
Assert-True ($setupFormText -notmatch '2\.10\.9') 'installer has no stale 2.10.9 fallback'
Assert-True (([regex]::Matches($setupFormText, '\?\? "3\.0\.0"')).Count -eq 3) 'installer fallback versions are 3.0.0'
$readmeText = Get-Content -LiteralPath (Join-Path $repo 'README.md') -Raw
Assert-True ($readmeText -match 'baseline: 3\.0\.0 \(NeoForge 26\.2\)') 'README reports 3.0.0 baseline'
$usageText = Get-Content -LiteralPath (Join-Path $repo 'docs\USAGE.md') -Raw
Assert-True ($usageText -match '26\.2\.0\.72') 'usage guide pins current NeoForge build'
Assert-True ($usageText -notmatch '26\.2\.0\.66') 'usage guide excludes stale NeoForge build'

$portableManifest = Get-Content -LiteralPath $portableManifestPath -Raw | ConvertFrom-Json
$manifestSources = @($portableManifest.entries | ForEach-Object { $_.sourcePath })
foreach ($requiredSource in @(
    'Convert-Forge1201-ToNeoForge262.ps1', 'Convert-JarToProject.ps1', 'Convert-OldJarToNeoForge262.ps1',
    'Open-CodexRepairSession.ps1', 'Open-GrokRepairSession.ps1', 'Build-WithDestinationJava.ps1', 'Lint-MigrationSkills.ps1',
    'scripts/Sync-CodexConverterWorkspace.ps1', 'scripts/Sync-GokuaiConverterWorkspace.ps1', 'gokuai-workspace-overlay',
    'lib/SolvedConversionIndex.json', 'lib/SolutionsIndex.ps1', 'lib/PrimerChangeIndex.json', 'lib/DependencyCatalog.json',
    'lib/overlays', 'lib/client-items', 'lib/primer_changes', 'lib/dep_changes', 'docs'
)) {
    Assert-True ($manifestSources -contains $requiredSource) "portable manifest source $requiredSource"
}
$appProjectText = Get-Content -LiteralPath (Join-Path $repo 'src\RB.LegacyJavaConverter\RB.LegacyJavaConverter.csproj') -Raw
Assert-True ($appProjectText -match 'Open-CodexRepairSession\.ps1') 'application packages native Codex launcher'
Assert-True ($appProjectText -match 'Sync-CodexConverterWorkspace\.ps1') 'application packages native workspace sync'
$releaseBuildText = Get-Content -LiteralPath (Join-Path $repo 'scripts\Build-Release.ps1') -Raw
Assert-True ($releaseBuildText -match 'Open-CodexRepairSession\.ps1') 'release build copies native Codex launcher'
Assert-True ($releaseBuildText -match 'Sync-CodexConverterWorkspace\.ps1') 'release build copies native workspace sync'
Assert-True ($releaseBuildText -notmatch 'Fix-in-Grok|C:\\gokuai') 'release build has no active legacy repair instructions'
$releasePublishText = Get-Content -LiteralPath (Join-Path $repo 'scripts\Publish-GitHubRelease.ps1') -Raw
Assert-True ($releasePublishText -match 'Repair with GokuCodexAI') 'release notes describe native repair action'
Assert-True ($releasePublishText -notmatch 'Fix-in-Grok|C:\\gokuai') 'release notes have no active legacy repair requirement'

$manifestFixture = Join-Path ([IO.Path]::GetTempPath()) ('legacy-portable-manifest-test-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $manifestFixture -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $manifestFixture 'version.txt') -Value '3.0.0' -Encoding ASCII
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $validatorOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $portableValidatorPath -Root $manifestFixture -ManifestPath $portableManifestPath -Layout Portable 2>&1 | Out-String
        $validatorExit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    Assert-True ($validatorExit -ne 0) 'portable validator rejects incomplete layout'
    Assert-True ($validatorOutput -match 'RB-Legacy-Java-Converter.exe') 'portable validator reports missing executable'
}
finally {
    if (Test-Path -LiteralPath $manifestFixture) { Remove-Item -LiteralPath $manifestFixture -Recurse -Force }
}

$powerShellSources = @(& git -C $repo ls-files --cached --others --exclude-standard -- '*.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate repository PowerShell sources with git ls-files' }
foreach ($relativePath in $powerShellSources) {
    $file = Get-Item -LiteralPath (Join-Path $repo ($relativePath -replace '/', '\'))
    $tokens = $null
    $errors = $null
    [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    Assert-Equal @($errors).Count 0 "PowerShell parse $relativePath"
}

foreach ($file in @('Convert-Forge1201-ToNeoForge262.ps1','Convert-JarToProject.ps1','Convert-OldJarToNeoForge262.ps1','lib\ModDependencyPipeline.ps1')) {
    $text = Get-Content -LiteralPath (Join-Path $repo $file) -Raw
    Assert-True ($text -match "26\.2\.0\.72") "26.2.0.72 default in $file"
    Assert-True ($text -notmatch "26\.2\.0\.66") "stale 26.2.0.66 absent from $file"
}

Write-Host "Regression tests passed: $script:passed" -ForegroundColor Green
