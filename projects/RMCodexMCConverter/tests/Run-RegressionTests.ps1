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

# Solved-conversion contract: declared passes, rules, transforms, and overlay ordering must be live.
$solvedIndex = Get-SolvedConversionIndex
$solvedBase = [pscustomobject]@{
    SchemaVersion=1; SourceVersion='1.21.4'; Loader='neoforge'; Framework='mcreator'; Confidence='high';
    Route='neoforge-1.21.x'; RecommendedPasses=@(Get-RecommendedMigrationPasses -Route 'neoforge-1.21.x');
    ApiFeatures=@(); Evidence=@()
}
$solvedProfile = Merge-SolvedConversionsIntoProfile -Profile $solvedBase -ModId 'thenewherobrinemod' -Index $solvedIndex
Assert-True (@($solvedProfile.SolvedRules) -contains 'entity-render-state') 'NewHerobrine forceRules merged into profile'
Assert-True (@($solvedProfile.SolvedTransforms) -contains 'custom-block-registration') 'NewHerobrine transforms merged into profile'
Assert-True (@($solvedProfile.AppliedSolutions.Id) -contains 'CASE-007-new-herobrine-1.21.4') 'NewHerobrine solved case matched'
$woodlandsBase = [pscustomobject]@{
    SchemaVersion=1; SourceVersion='1.21.1'; Loader='neoforge'; Framework='mcreator'; Confidence='high';
    Route='neoforge-1.21.x'; RecommendedPasses=@(Get-RecommendedMigrationPasses -Route 'neoforge-1.21.x');
    ApiFeatures=@(); Evidence=@()
}
$woodlandsProfile = Merge-SolvedConversionsIntoProfile -Profile $woodlandsBase -ModId 'woodlands' -Index $solvedIndex
Assert-True (@($woodlandsProfile.AppliedSolutions.Id) -contains 'CASE-008-woodlands-1.21.1') 'Woodlands solved case matched'
Assert-True (Test-Path -LiteralPath (Join-Path $repo 'lib\overlays\woodlands\1.21.1.zip') -PathType Leaf) 'Woodlands verified overlay packaged'
$woodlandsCase = @($solvedIndex.solutions | Where-Object id -eq 'CASE-008-woodlands-1.21.1')[0]
Assert-True (@($woodlandsCase.overlays[0].deletePaths) -contains 'src/main/java/net/mcreator/woodlands/init/WoodlandsModTrades.java') 'Woodlands obsolete Java deletion declared'
$overlayFixture = Join-Path ([IO.Path]::GetTempPath()) ('woodlands-overlay-test-' + [guid]::NewGuid().ToString('N'))
try {
    $required = Join-Path $overlayFixture 'src\main\java\net\mcreator\woodlands\WoodlandsMod.java'
    $obsoleteTrade = Join-Path $overlayFixture 'src\main\java\net\mcreator\woodlands\init\WoodlandsModTrades.java'
    $obsoleteDimension = Join-Path $overlayFixture 'src\main\java\net\mcreator\woodlands\world\dimension\WoodLandDimension.java'
    New-Item -ItemType Directory -Path (Split-Path $required),(Split-Path $obsoleteTrade),(Split-Path $obsoleteDimension) -Force | Out-Null
    Set-Content -LiteralPath $required -Value 'class WoodlandsMod {}'
    Set-Content -LiteralPath $obsoleteTrade -Value 'class WoodlandsModTrades {}'
    Set-Content -LiteralPath $obsoleteDimension -Value 'class WoodLandDimension {}'
    $overlayResult = Apply-SolvedConversionOverlays -Root $overlayFixture -Profile $woodlandsProfile -ModId 'woodlands' -ToolRoot $repo -Index $solvedIndex
    Assert-True (-not (Test-Path -LiteralPath $obsoleteTrade)) 'Woodlands overlay deletes obsolete trade subscriber'
    Assert-True (-not (Test-Path -LiteralPath $obsoleteDimension)) 'Woodlands overlay deletes obsolete dimension effects class'
    Assert-True (@($overlayResult.Overlays) -contains 'woodlands/1.21.1.zip') 'Woodlands overlay applied in deletion fixture'
    $fortress = Get-Content -LiteralPath (Join-Path $overlayFixture 'src\main\resources\data\woodlands\worldgen\structure\ruined_fortress.json') -Raw | ConvertFrom-Json
    $statue = Get-Content -LiteralPath (Join-Path $overlayFixture 'src\main\resources\data\woodlands\worldgen\structure\wooden_statue.json') -Raw | ConvertFrom-Json
    Assert-Equal $fortress.project_start_to_heightmap 'WORLD_SURFACE_WG' 'Woodlands fortress projects to 26.2 world surface'
    Assert-Equal $fortress.step 'raw_generation' 'Woodlands fortress uses verified generation phase'
    Assert-Equal $statue.project_start_to_heightmap 'WORLD_SURFACE_WG' 'Woodlands statue projects to 26.2 world surface'
    Assert-Equal $statue.step 'raw_generation' 'Woodlands statue uses verified generation phase'
}
finally {
    if (Test-Path -LiteralPath $overlayFixture) { Remove-Item -LiteralPath $overlayFixture -Recurse -Force }
}
$worldgenFixture = Join-Path ([IO.Path]::GetTempPath()) ('worldgen-262-test-' + [guid]::NewGuid().ToString('N'))
try {
    $biomeDir = Join-Path $worldgenFixture 'src\main\resources\data\example\worldgen\biome'
    $treeDir = Join-Path $worldgenFixture 'src\main\resources\data\example\worldgen\configured_feature'
    $dimensionDir = Join-Path $worldgenFixture 'src\main\resources\data\example\dimension'
    New-Item -ItemType Directory -Path $biomeDir,$treeDir,$dimensionDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $biomeDir 'test.json') -Value '{"carvers":{},"features":[]}'
    Set-Content -LiteralPath (Join-Path $treeDir 'test.json') -Value '{"type":"minecraft:tree","config":{"dirt_provider":{"type":"minecraft:simple_state_provider","state":{"Name":"minecraft:oak_planks"}}}}'
    Set-Content -LiteralPath (Join-Path $dimensionDir 'test.json') -Value '{"generator":{"settings":{"noise_router":{"barrier":0}}}}'
    Assert-Equal (Invoke-Minecraft262WorldgenDataPass -Root $worldgenFixture) 3 'Woodlands worldgen codec fixture touched'
    $biome = Get-Content -LiteralPath (Join-Path $biomeDir 'test.json') -Raw | ConvertFrom-Json
    $tree = Get-Content -LiteralPath (Join-Path $treeDir 'test.json') -Raw | ConvertFrom-Json
    $dimension = Get-Content -LiteralPath (Join-Path $dimensionDir 'test.json') -Raw | ConvertFrom-Json
    Assert-Equal @($biome.carvers).Count 0 'empty biome carvers object becomes array'
    Assert-Equal $tree.config.below_trunk_provider.type 'minecraft:rule_based_state_provider' 'tree below-trunk provider added'
    Assert-Equal $tree.config.below_trunk_provider.rules[0].then.state.Name 'minecraft:oak_planks' 'tree custom dirt provider preserved'
    Assert-True ($dimension.generator.settings.noise_router.PSObject.Properties.Name -contains 'preliminary_surface_level') 'noise-router preliminary surface level added'
}
finally {
    if (Test-Path -LiteralPath $worldgenFixture) { Remove-Item -LiteralPath $worldgenFixture -Recurse -Force }
}
$knownTransforms = @('custom-block-registration','client-package-moves','cutout-render-type','submit-custom-geometry','fusion-official')
$declaredTransforms = @($solvedIndex.solutions.transforms) + @($solvedIndex.bandDefaults.transforms) | Where-Object { $_ } | Select-Object -Unique
foreach ($transform in $declaredTransforms) { Assert-True ($knownTransforms -contains $transform) "known solved transform $transform" }
$knownRules = @(Get-PrimerMigrationRules -SourceVersion '1.20.1')
$declaredRules = @($solvedIndex.solutions.forceRules) + @($solvedIndex.bandDefaults.forceRules) | Where-Object { $_ } | Select-Object -Unique
foreach ($rule in $declaredRules) { Assert-True ($knownRules -contains $rule) "known solved rule $rule" }
$converterText = Get-Content -LiteralPath (Join-Path $repo 'Convert-Forge1201-ToNeoForge262.ps1') -Raw
Assert-True ($converterText.Contains("LivingEntity.getSlotForHand(context.getHand())', 'context.getHand()")) 'Woodlands InteractionHand repair hardened'
Assert-True ($converterText.Contains("import net.minecraft.BlockUtil.FoundRectangle;', 'import net.minecraft.util.BlockUtil.FoundRectangle;")) 'Woodlands BlockUtil package repair hardened'
Assert-True ($converterText -match 'Get-PrimerMigrationRules[^\r\n]+Profile\.SolvedRules') 'exact primer execution consumes SolvedRules'
Assert-True ($converterText -match 'function Invoke-MinecraftEntitySubpackageRemapPass' -and $converterText.Contains('Invoke-MinecraftEntitySubpackageRemapPass -Root $Root')) 'client-package-moves dispatcher target exists'
Assert-True ($converterText.IndexOf("Solved-conversion named transforms") -lt $converterText.IndexOf("Solved-conversion semantic overlays")) 'transforms execute before overlays'
Assert-True ($converterText.IndexOf("Solved-conversion semantic overlays") -gt $converterText.IndexOf("Item-model-touched")) 'overlays are the final source/resource mutation'

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
