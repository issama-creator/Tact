Add-Type -AssemblyName System.Drawing
$path = 'C:\Users\islam\.cursor\projects\c-Users-islam-Desktop-work-flutter-projects-tact-tact\assets\c__Users_islam_AppData_Roaming_Cursor_User_workspaceStorage_fdfdde39c6d54f6afecbbcdec3d7df36_images_image-43296c62-c2b9-4286-8840-6f5531e8f639.png'
$img = [System.Drawing.Bitmap]::FromFile($path)
Write-Host "size $($img.Width)x$($img.Height)"

function Test-Key([System.Drawing.Color]$c) {
    $r = $c.R; $g = $c.G
    return ($r -gt 45 -and $r -lt 100 -and [Math]::Abs($r - $g) -lt 15)
}

foreach ($yfrac in @(0.58, 0.64, 0.70, 0.76, 0.82, 0.88)) {
    $y = [int]($img.Height * $yfrac)
    $left = -1
    $right = -1
    $runs = 0
    $in = $false
    for ($x = 0; $x -lt $img.Width; $x++) {
        $k = Test-Key ($img.GetPixel($x, $y))
        if ($k) {
            if (-not $in) { $runs++; $in = $true }
            if ($left -lt 0) { $left = $x }
            $right = $x
        } else {
            $in = $false
        }
    }
    $rm = $img.Width - 1 - $right
    Write-Host ("y={0} ({1:n2}) left={2} right={3} span={4} runs={5} Lmarg={2} Rmarg={6}" -f $y, $yfrac, $left, $right, ($right - $left), $runs, $rm)
}
$img.Dispose()
