$code = Get-Content -Raw 'lib/features/search/presentation/screens/flight_details_screen.dart'
$stack = New-Object System.Collections.Generic.List[string]
$lineStack = New-Object System.Collections.Generic.List[int]

$lines = $code -split "`r?`n"

for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    for ($j = 0; $j -lt $line.Length; $j++) {
        $c = $line[$j]
        if ($c -eq '{' -or $c -eq '(' -or $c -eq '[') {
            $stack.Add($c)
            $lineStack.Add($i + 1)
        } elseif ($c -eq '}' -or $c -eq ')' -or $c -eq ']') {
            if ($stack.Count -eq 0) {
                Write-Host "Unmatched $c at line $($i + 1)"
            } else {
                $top = $stack[$stack.Count - 1]
                $topLine = $lineStack[$lineStack.Count - 1]
                $stack.RemoveAt($stack.Count - 1)
                $lineStack.RemoveAt($lineStack.Count - 1)
                
                $expected = if ($top -eq '{') { '}' } elseif ($top -eq '(') { ')' } else { ']' }
                if ($c -ne $expected) {
                    Write-Host "Mismatched $c at line $($i + 1), expected $expected to match $top at line $topLine"
                }
            }
        }
    }
}

if ($stack.Count -gt 0) {
    Write-Host "Leftover unmatched braces: $($stack.Count)"
} else {
    Write-Host "All braces match perfectly!"
}
