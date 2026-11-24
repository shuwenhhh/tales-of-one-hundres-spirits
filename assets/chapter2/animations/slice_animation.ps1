Add-Type -AssemblyName System.Drawing

$outputRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$frameSize = 160

function Export-Frames {
    param(
        [string] $SourceName,
        [string] $Prefix,
        [int] $Columns,
        [int] $Rows,
        [int] $DestinationX,
        [int] $DestinationWidth,
        [switch] $AlignFeet
    )
    $sourcePath = Join-Path $outputRoot $SourceName
    $minimumIsland = if ($Prefix -eq 'thrust') { 40 } elseif ($Prefix -eq 'walk') { 24 } else { 8 }
    $source = [System.Drawing.Bitmap]::new($sourcePath)
    try {
        $cellWidth = [int]($source.Width / $Columns)
        $cellHeight = [int]($source.Height / $Rows)
        for ($i = 0; $i -lt ($Columns * $Rows); $i++) {
            $sourceRect = [System.Drawing.Rectangle]::new(($i % $Columns) * $cellWidth, [int][math]::Floor($i / $Columns) * $cellHeight, $cellWidth, $cellHeight)
            $frame = [System.Drawing.Bitmap]::new($frameSize, $frameSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [System.Drawing.Graphics]::FromImage($frame)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $destinationRect = [System.Drawing.Rectangle]::new($DestinationX, 0, $DestinationWidth, $frameSize)
                $graphics.DrawImage($source, $destinationRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
            } finally {
                $graphics.Dispose()
            }
            for ($y = 0; $y -lt $frameSize; $y++) {
                for ($x = 0; $x -lt $frameSize; $x++) {
                    $pixel = $frame.GetPixel($x, $y)
                    $magentaSpill = $pixel.R -gt 150 -and $pixel.B -gt 130 -and $pixel.G -lt 105
                    $redSpill = $pixel.R -gt 150 -and $pixel.G -lt 85 -and $pixel.B -lt 100
                    $walkEdgeFleck = $Prefix -eq 'walk' -and $x -lt 45 -and $y -gt 135
                    $thrustEdgeFleck = $Prefix -eq 'thrust' -and $i -in @(1, 2) -and $x -ge 112 -and $y -lt 110
                    if ($pixel.A -lt 128 -or $magentaSpill -or $redSpill -or $walkEdgeFleck -or $thrustEdgeFleck) {
                        $frame.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                    }
                }
            }
            # Generated transparent strips can contain single-pixel color flecks.
            # Remove only tiny detached islands; the character and slash remain intact.
            $seen = [bool[]]::new($frameSize * $frameSize)
            for ($y = 0; $y -lt $frameSize; $y++) {
                for ($x = 0; $x -lt $frameSize; $x++) {
                    $start = $y * $frameSize + $x
                    if ($seen[$start] -or $frame.GetPixel($x, $y).A -eq 0) { continue }
                    $queue = [System.Collections.Generic.Queue[int]]::new()
                    $island = [System.Collections.Generic.List[int]]::new()
                    $touchesBody = $false
                    $queue.Enqueue($start)
                    $seen[$start] = $true
                    while ($queue.Count -gt 0) {
                        $at = $queue.Dequeue()
                        $island.Add($at)
                        $cx = $at % $frameSize
                        $cy = [int][math]::Floor($at / $frameSize)
                        if ($cx -ge 50 -and $cx -le 110 -and $cy -ge 40 -and $cy -le 140) { $touchesBody = $true }
                        foreach ($offset in @(-1, 1, (-$frameSize), $frameSize)) {
                            if ($offset -eq -1 -and $cx -eq 0) { continue }
                            if ($offset -eq 1 -and $cx -eq ($frameSize - 1)) { continue }
                            $ni = $at + $offset
                            if ($ni -lt 0 -or $ni -ge ($frameSize * $frameSize)) { continue }
                            $nx = $ni % $frameSize
                            $ny = [int][math]::Floor($ni / $frameSize)
                            if (-not $seen[$ni] -and $frame.GetPixel($nx, $ny).A -gt 0) {
                                $seen[$ni] = $true
                                $queue.Enqueue($ni)
                            }
                        }
                    }
                    if ($island.Count -lt $minimumIsland -or ($Prefix -eq 'thrust' -and -not $touchesBody)) {
                        foreach ($at in $island) {
                            $frame.SetPixel($at % $frameSize, [int][math]::Floor($at / $frameSize), [System.Drawing.Color]::Transparent)
                        }
                    }
                }
            }
            if ($AlignFeet) {
                $bottom = -1
                for ($scanY = $frameSize - 1; $scanY -ge 0 -and $bottom -lt 0; $scanY--) {
                    for ($scanX = 0; $scanX -lt $frameSize; $scanX++) {
                        if ($frame.GetPixel($scanX, $scanY).A -gt 0) { $bottom = $scanY; break }
                    }
                }
                if ($bottom -ge 0) {
                    $aligned = [System.Drawing.Bitmap]::new($frameSize, $frameSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                    $alignGraphics = [System.Drawing.Graphics]::FromImage($aligned)
                    $alignGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                    $alignGraphics.DrawImageUnscaled($frame, 0, 150 - $bottom)
                    $alignGraphics.Dispose()
                    $frame.Dispose()
                    $frame = $aligned
                }
            }
            $path = Join-Path $outputRoot ('{0}-{1:D2}.png' -f $Prefix, $i)
            try {
                $frame.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
            } finally {
                $frame.Dispose()
            }
        }
    } finally {
        $source.Dispose()
    }
}

Export-Frames -SourceName 'peach-walk-source.png' -Prefix 'walk' -Columns 6 -Rows 1 -DestinationX 40 -DestinationWidth 80
Export-Frames -SourceName 'peach-slash-source.png' -Prefix 'slash' -Columns 3 -Rows 2 -DestinationX 0 -DestinationWidth 160
Export-Frames -SourceName 'peach-hurt-source.png' -Prefix 'hurt' -Columns 3 -Rows 1 -DestinationX 0 -DestinationWidth 160
Export-Frames -SourceName 'peach-thrust-source.png' -Prefix 'thrust' -Columns 6 -Rows 1 -DestinationX 40 -DestinationWidth 80
Export-Frames -SourceName 'peach-leap-source.png' -Prefix 'leap' -Columns 4 -Rows 1 -DestinationX 0 -DestinationWidth 160 -AlignFeet
Export-Frames -SourceName 'peach-cast-source.png' -Prefix 'cast' -Columns 3 -Rows 1 -DestinationX 0 -DestinationWidth 160
