param([string[]] $Kinds = @('walk', 'slash', 'hurt', 'thrust', 'leap', 'cast'))

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
foreach ($kind in $Kinds) {
    $frameCount = switch ($kind) { 'hurt' { 3 } 'cast' { 3 } 'leap' { 4 } default { 6 } }
    $svgWidth = $frameCount * 160
    $xml = [System.Text.StringBuilder]::new()
    [void]$xml.Append(('<svg xmlns="http://www.w3.org/2000/svg" width="{0}" height="160" viewBox="0 0 {0} 160" shape-rendering="crispEdges">' -f $svgWidth))
    [void]$xml.Append("<title>Peach Spirit $kind pixel-vector frames</title>")
    for ($frameIndex = 0; $frameIndex -lt $frameCount; $frameIndex++) {
        $path = Join-Path $root ('{0}-{1:D2}.png' -f $kind, $frameIndex)
        $bitmap = [System.Drawing.Bitmap]::new($path)
        try {
            [void]$xml.Append(('<g transform="translate({0} 0)">' -f ($frameIndex * 160)))
            for ($y = 0; $y -lt $bitmap.Height; $y++) {
                $x = 0
                while ($x -lt $bitmap.Width) {
                    $color = $bitmap.GetPixel($x, $y)
                    if ($color.A -lt 128) { $x++; continue }
                    $start = $x
                    $rgb = $color.ToArgb()
                    while ($x -lt $bitmap.Width) {
                        $next = $bitmap.GetPixel($x, $y)
                        if ($next.A -lt 128 -or $next.ToArgb() -ne $rgb) { break }
                        $x++
                    }
                    $hex = '{0:X2}{1:X2}{2:X2}' -f $color.R, $color.G, $color.B
                    [void]$xml.Append(('<rect x="{0}" y="{1}" width="{2}" height="1" fill="#{3}"/>' -f $start, $y, ($x - $start), $hex))
                }
            }
            [void]$xml.Append('</g>')
        } finally {
            $bitmap.Dispose()
        }
    }
    [void]$xml.Append('</svg>')
    [System.IO.File]::WriteAllText((Join-Path $root "$kind-vector.svg"), $xml.ToString(), [System.Text.Encoding]::UTF8)
}
