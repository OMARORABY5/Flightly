$files = Get-ChildItem -Path "mobile\lib" -Recurse -Filter "*.dart"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    $changed = $false

    if ($content -match '\\\$\\\$\{') {
        $content = $content -replace '\\\$\\\$\{', 'EGP ${'
        $changed = $true
    }
    
    if ($content -match '\\\$(\d)') {
        $content = [regex]::Replace($content, '\\\$(\d+)', 'EGP $1')
        $changed = $true
    }

    if ($content -match '-\\\$\\\$\{') {
        $content = $content -replace '-\\\$\\\$\{', '-EGP ${'
        $changed = $true
    }
    
    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
    }
}
