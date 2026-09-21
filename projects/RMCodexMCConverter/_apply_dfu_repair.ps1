param([Parameter(Mandatory)][string]$JavaRoot)

$ErrorActionPreference = 'Stop'
$touched = 0

Get-ChildItem -LiteralPath $JavaRoot -Recurse -Filter '*.java' -File | ForEach-Object {
    $filePath = $_.FullName
    $t = [System.IO.File]::ReadAllText($filePath)
    $o = $t

    $t = [regex]::Replace($t, '(?m)(Codec\s*<\s*([A-Za-z_][\w]*)\s*>\s+\w+\s*=\s*RecordCodecBuilder)\.(create)\s*\(', '${1}.<$2>$3(')
    $t = [regex]::Replace($t, '(?m)(MapCodec\s*<\s*([A-Za-z_][\w]*(?:\.[A-Za-z_][\w]*)*)\s*>\s+\w+\s*=\s*RecordCodecBuilder)\.(mapCodec)\s*\(', '${1}.<$2>$3(')
    $t = [regex]::Replace($t, '(?m)(Codec\s*<\s*([A-Za-z_][\w]*\.[A-Za-z_][\w]*)\s*>\s+\w+\s*=\s*RecordCodecBuilder)\.(create)\s*\(', '${1}.<$2>$3(')

    $components = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($rm in [regex]::Matches($t, '(?m)\brecord\s+\w+\s*\(([^)]*)\)')) {
        $paramList = $rm.Groups[1].Value
        if (-not $paramList.Trim()) { continue }
        $depth = 0
        $cur = New-Object System.Text.StringBuilder
        $parts = New-Object System.Collections.Generic.List[string]
        foreach ($ch in $paramList.ToCharArray()) {
            if ($ch -eq '<' -or $ch -eq '(') { $depth++ }
            elseif ($ch -eq '>' -or $ch -eq ')') { if ($depth -gt 0) { $depth-- } }
            elseif ($ch -eq ',' -and $depth -eq 0) {
                $parts.Add($cur.ToString()) | Out-Null
                [void]$cur.Clear()
                continue
            }
            [void]$cur.Append($ch)
        }
        if ($cur.Length -gt 0) { $parts.Add($cur.ToString()) | Out-Null }
        foreach ($p in $parts) {
            if ($p -match '(?s)([A-Za-z_][\w]*)\s*$') { [void]$components.Add($matches[1]) }
        }
    }

    if ($components.Count -gt 0) {
        $sb = New-Object System.Text.StringBuilder
        $i = 0
        while ($i -lt $t.Length) {
            $idx = $t.IndexOf('.validate(', $i)
            if ($idx -lt 0) { [void]$sb.Append($t.Substring($i)); break }
            [void]$sb.Append($t.Substring($i, $idx - $i))
            $startArgs = $idx + '.validate('.Length
            $depth = 1
            $j = $startArgs
            while ($j -lt $t.Length -and $depth -gt 0) {
                $c = $t[$j]
                if ($c -eq '(') { $depth++ }
                elseif ($c -eq ')') { $depth-- }
                $j++
            }
            $body = $t.Substring($startArgs, ($j - 1) - $startArgs)
            foreach ($comp in @($components)) {
                $rx = [regex]::new("(?<![\w.])([a-z_][\w]*)\.$([regex]::Escape($comp))\b(?!\s*\()")
                $body = $rx.Replace($body, {
                        param($m)
                        $recv = $m.Groups[1].Value
                        if ($recv -eq 'this' -or $recv -eq 'super') { return $m.Value }
                        return ($recv + '.' + $comp + '()')
                    })
            }
            [void]$sb.Append('.validate(')
            [void]$sb.Append($body)
            [void]$sb.Append(')')
            $i = $j
        }
        $t = $sb.ToString()
    }

    if ($t -match '@Mixin\b') {
        $t = [regex]::Replace($t, '\(\s*([A-Za-z_][\w]*)\s*\)\s*this\b', '($1)(Object)this')
        $t = $t -replace '\((\w+)\)\(Object\)\(Object\)this\b', '($1)(Object)this'
    }

    $t = $t -replace 'import\s+org\.checkerframework\.checker\.nullness\.qual\.[^;]+;\r?\n', ''
    $t = $t -replace '@NonNull\b\s*', ''

    if ($t -ne $o) {
        [System.IO.File]::WriteAllText($filePath, $t)
        $script:touched++
    }
}

Write-Host "DFU repair touched $touched file(s)"
