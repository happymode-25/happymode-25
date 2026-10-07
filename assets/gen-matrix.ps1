$ErrorActionPreference = 'Stop'

$glyphs = '0123456789ABCDEFabcdef<>[]{}/*+=$#@%&!?/:;~^|'
$lh = 18

function New-MatrixColumnGlyphs {
    param($Rnd, $Count)
    $a = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $Count; $i++) {
        $idx = $Rnd.Next(0, $glyphs.Length)
        $a.Add($glyphs[$idx].ToString())
    }
    return $a
}

function New-MatrixSvg {
    param(
        [int]$Width, [int]$Height, [int]$Cols,
        [string]$OutPath, [string]$SeedLabel
    )
    $rnd = New-Object System.Random($SeedLabel.GetHashCode())
    $colW = [Math]::Floor($Width / [double]$Cols)
    # glyphCount/offset are derived from the real content height so the two
    # stacked copies are an exact repeat; otherwise the loop jumps.
    $glyphCount = [Math]::Ceiling(($Height * 2) / [double]$lh)
    $contentH = $glyphCount * $lh
    $copies = 2

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<svg xmlns="http://www.w3.org/2000/svg" width="' + $Width + '" height="' + $Height + '" viewBox="0 0 ' + $Width + ' ' + $Height + '" role="img" aria-label="Matrix rain">')
    [void]$sb.AppendLine('<rect width="' + $Width + '" height="' + $Height + '" fill="#0d1117"/>')
    # Content is two identical blocks of height contentH, so the frame at
    # translateY(-contentH) is identical to the frame at translateY(0).
    # Animating that span slides the glyphs downward: seamless falling rain.
    [void]$sb.AppendLine('<style>.cl{animation-name:fall;animation-timing-function:linear;animation-iteration-count:infinite;}@keyframes fall{from{transform:translateY(-' + $contentH + 'px)}to{transform:translateY(0)}}</style>')

    for ($c = 0; $c -lt $Cols; $c++) {
        $x = [int](($c * $colW) + [Math]::Floor($colW / 2))
        $g = New-MatrixColumnGlyphs -Rnd $rnd -Count $glyphCount
        $dur = 4.0 + ($rnd.NextDouble() * 6.0)
        $delay = -($rnd.NextDouble() * $dur)
        $bright = $rnd.Next(0, 3)
        $col = if ($bright -eq 0) { '#00ff41' } elseif ($bright -eq 1) { '#00d9ff' } else { '#0f7a35' }

        [void]$sb.Append('<g class="cl" style="animation-duration:' + $dur.ToString('0.00') + 's;animation-delay:' + $delay.ToString('0.00') + 's">')

        for ($copy = 0; $copy -lt $copies; $copy++) {
            $startY = $copy * $contentH
            [void]$sb.Append('<text x="' + $x + '" y="' + ($startY + $lh) + '" text-anchor="middle" fill="' + $col + '" font-family="Cascadia Mono,Fira Code,Consolas,monospace" font-size="15">')
            for ($i = 0; $i -lt $glyphCount; $i++) {
                $glyph = $g[$i] -replace '&', '&amp;' -replace '<', '&lt;'
                $op = if ($i -lt 3) { '1' } elseif ($i -lt 12) { '0.75' } else { '0.4' }
                if ($i -eq 0) {
                    [void]$sb.Append('<tspan x="' + $x + '" dy="' + $lh + '" fill="#d6ffe6" opacity="' + $op + '">' + $glyph + '</tspan>')
                } else {
                    [void]$sb.Append('<tspan x="' + $x + '" dy="' + $lh + '" opacity="' + $op + '">' + $glyph + '</tspan>')
                }
            }
            [void]$sb.Append('</text>')
        }
        [void]$sb.AppendLine('</g>')
    }

    [void]$sb.AppendLine('</svg>')
    [System.IO.File]::WriteAllText($OutPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ("wrote " + $OutPath + "  bytes=" + (Get-Item $OutPath).Length)
}

New-MatrixSvg -Width 900 -Height 200 -Cols 34 -OutPath "$PSScriptRoot\matrix-header.svg" -SeedLabel "happymode-header"
New-MatrixSvg -Width 900 -Height 140 -Cols 34 -OutPath "$PSScriptRoot\matrix-footer.svg" -SeedLabel "happymode-footer"
