$files = Get-ChildItem -Path "mobile\lib" -Recurse -Filter "*.dart"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    $changed = $false

    # Match `+EGP ${...}` -> `+${...} EGP`
    if ($content -match '\+EGP \$\{([^\}]+)\}') {
        $content = [regex]::Replace($content, '\+EGP \$\{([^\}]+)\}', '+${$1} EGP')
        $changed = $true
    }

    # Match `-EGP ${...}` -> `-${...} EGP`
    if ($content -match '-EGP \$\{([^\}]+)\}') {
        $content = [regex]::Replace($content, '-EGP \$\{([^\}]+)\}', '-${$1} EGP')
        $changed = $true
    }

    # Match `EGP ${...}` -> `${...} EGP`
    if ($content -match '(?<![-+])EGP \$\{([^\}]+)\}') {
        $content = [regex]::Replace($content, '(?<![-+])EGP \$\{([^\}]+)\}', '${$1} EGP')
        $changed = $true
    }

    # Match `EGP 100` -> `100 EGP` (including commas, periods, plus signs)
    if ($content -match 'EGP (\d+(?:,\d+)?(?:\.\d+)?\+?)') {
        $content = [regex]::Replace($content, 'EGP (\d+(?:,\d+)?(?:\.\d+)?\+?)', '$1 EGP')
        $changed = $true
    }

    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
    }
}
