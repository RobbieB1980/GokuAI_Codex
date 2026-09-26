Set-StrictMode -Version Latest

function Set-JsonProperty {
    param([Parameter(Mandatory)]$Object, [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)]$Value)
    $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
}

function Remove-JsonProperty {
    param([Parameter(Mandatory)]$Object, [Parameter(Mandatory)][string]$Name)
    if ($null -ne $Object.PSObject.Properties[$Name]) { $Object.PSObject.Properties.Remove($Name) }
}

function Read-JsonFile([string]$Path) { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }

function Write-JsonFile([string]$Path, $Value) {
    $Value | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Update-TextVersionMarkers([string]$Path, [string]$NeoVersion) {
    $text = Get-Content -LiteralPath $Path -Raw
    $updated = $text -replace '(?im)(minecraft[_\.-]version\s*[=:]\s*["'']?)26\.2(["'']?)', '$126.3$2'
    $updated = $updated -replace '(?im)(neo[_\.-]version\s*[=:]\s*["'']?)26\.2(?:\.\d+)?(?:-[^"''\s]+)?(["'']?)', ('$1' + $NeoVersion + '$2')
    if ($updated -ne $text) { Set-Content -LiteralPath $Path -Value $updated -Encoding UTF8; return $true }
    return $false
}

function Convert-NoiseSettings($Json, [System.Collections.Generic.List[string]]$Warnings) {
    if ($null -ne $Json.PSObject.Properties['surface_rule']) {
        Set-JsonProperty $Json 'material_rule' $Json.surface_rule
        Remove-JsonProperty $Json 'surface_rule'
    }
    if ($null -ne $Json.PSObject.Properties['preliminary_surface_level']) {
        Set-JsonProperty $Json 'chunk_surface_level' $Json.preliminary_surface_level
        Remove-JsonProperty $Json 'preliminary_surface_level'
    }
    $router = $Json.noise_router
    if ($null -eq $router) { return }
    $moved = @('barrier','fluid_level_floodedness','fluid_level_spread','lava')
    $aquifers = $null
    foreach ($name in $moved) {
        if ($null -ne $router.PSObject.Properties[$name]) {
            if ($null -eq $aquifers) { $aquifers = [pscustomobject]@{} }
            Set-JsonProperty $aquifers $name $router.$name
            Remove-JsonProperty $router $name
        }
    }
    if ($null -ne $aquifers) { Set-JsonProperty $Json 'aquifers' $aquifers }
    foreach ($name in @('ore_veins_enabled','vein_toggle','vein_ridged','vein_gap','size_horizontal','size_vertical')) {
        if ($null -ne $Json.PSObject.Properties[$name] -or $null -ne $router.PSObject.Properties[$name]) {
            $Warnings.Add("Manual worldgen review required for $name")
        }
    }
}

function Invoke-RB262To263 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [Parameter(Mandatory)][string]$OutputPath,
        [string]$NeoVersion = ''
    )
    $inputFull = (Resolve-Path -LiteralPath $InputPath -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath $OutputPath)) { $outputFull = [IO.Path]::GetFullPath($OutputPath) } else { $outputFull = (Resolve-Path -LiteralPath $OutputPath).Path }
    if ($inputFull.TrimEnd('\') -eq $outputFull.TrimEnd('\')) { throw 'Input and output paths must be different.' }
    $props = Get-ChildItem -LiteralPath $inputFull -Recurse -File -Include '*.properties','*.gradle','*.gradle.kts','mods.toml' -ErrorAction SilentlyContinue
    $sourceText = ($props | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
    if ($sourceText -notmatch '(?<!\d)26\.2(?:\.\d+)?(?!\d)') { return [pscustomobject]@{ Status='Rejected'; Reason='Input does not contain an exact NeoForge/Minecraft 26.2 marker.' } }
    if ([string]::IsNullOrWhiteSpace($NeoVersion)) { throw 'NeoVersion is required until an official stable NeoForge 26.3 pin is available.' }
    New-Item -ItemType Directory -Path $outputFull -Force | Out-Null
    Get-ChildItem -LiteralPath $inputFull -Force | Copy-Item -Destination $outputFull -Recurse -Force
    $warnings = [System.Collections.Generic.List[string]]::new()
    $changed = [System.Collections.Generic.List[string]]::new()
    foreach ($file in Get-ChildItem -LiteralPath $outputFull -Recurse -File -Include '*.properties','*.gradle','*.gradle.kts','mods.toml') {
        if (Update-TextVersionMarkers $file.FullName $NeoVersion) { $changed.Add($file.FullName.Substring($outputFull.Length + 1)) }
    }
    foreach ($file in Get-ChildItem -LiteralPath $outputFull -Recurse -File -Filter 'pack.mcmeta') {
        $json = Read-JsonFile $file.FullName
        $hasData = Test-Path -LiteralPath (Join-Path (Split-Path $file.FullName) 'data')
        Set-JsonProperty $json.pack 'pack_format' $(if ($hasData) { 121.0 } else { 97.1 })
        Write-JsonFile $file.FullName $json
        $changed.Add($file.FullName.Substring($outputFull.Length + 1))
    }
    foreach ($file in Get-ChildItem -LiteralPath $outputFull -Recurse -File -Filter '*.json') {
        if ($file.FullName -notmatch '\\worldgen\\noise_settings\\') { continue }
        $json = Read-JsonFile $file.FullName
        Convert-NoiseSettings $json $warnings
        Write-JsonFile $file.FullName $json
        $changed.Add($file.FullName.Substring($outputFull.Length + 1))
    }
    $manifest = [ordered]@{ target_id='rb-26.2-to-26.3'; status='Converted'; source_path=$inputFull; output_path=$outputFull; source_minecraft='26.2'; target_minecraft='26.3'; target_neo_version=$NeoVersion; changed_files=@($changed); warnings=@($warnings); validation=[ordered]@{ deterministic_changes=$true; build='not-run'; runtime='not-run'; content='not-run' } }
    Write-JsonFile (Join-Path $outputFull 'conversion-manifest.json') $manifest
    $evidence = @('# RB 26.2 → 26.3 migration evidence','',"Target NeoForge version: $NeoVersion",'', '## Changed files') + @($changed | ForEach-Object { '- ' + $_ }) + @('', '## Remaining review') + @($warnings | ForEach-Object { '- ' + $_ }) + @('- Client/rendering Java APIs require AST or Codex repair review.', '- Dependency compatibility and Gradle build remain unvalidated until the target NeoForge artifact is available.')
    Set-Content -LiteralPath (Join-Path $outputFull 'MIGRATION_EVIDENCE.md') -Value $evidence -Encoding UTF8
    return [pscustomobject]$manifest
}
