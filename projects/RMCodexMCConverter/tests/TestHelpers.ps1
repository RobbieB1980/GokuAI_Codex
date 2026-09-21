function Assert-TextFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock]$Transform,
        [Parameter(Mandatory)][string]$FixtureRoot,
        [Parameter(Mandatory)][string]$Name
    )

    $inputPath = Join-Path $FixtureRoot 'input.java'
    $expectedPath = Join-Path $FixtureRoot 'expected.java'
    $input = [IO.File]::ReadAllText($inputPath)
    $expected = [IO.File]::ReadAllText($expectedPath)
    $project = Join-Path ([IO.Path]::GetTempPath()) ('legacy-transform-test-' + [guid]::NewGuid().ToString('N'))
    $javaDir = Join-Path $project 'src\main\java\example'
    $javaFile = Join-Path $javaDir 'Fixture.java'

    try {
        New-Item -ItemType Directory -Path $javaDir -Force | Out-Null
        [IO.File]::WriteAllText($javaFile, $input)
        & $Transform $project
        $actual = [IO.File]::ReadAllText($javaFile)
        if ($actual -cne $expected) { throw "${Name}: first transform did not match expected output" }
        & $Transform $project
        $second = [IO.File]::ReadAllText($javaFile)
        if ($second -cne $actual) { throw "${Name}: transform was not idempotent" }
    }
    finally {
        if (Test-Path -LiteralPath $project) { Remove-Item -LiteralPath $project -Recurse -Force }
    }
}
