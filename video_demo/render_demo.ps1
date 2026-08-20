param(
    [int]$Fps = 30,
    [int]$Width = 1280,
    [int]$Height = 720,
    [double]$Duration = 24.0,
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ffmpeg = Join-Path $scriptRoot "tools\ffmpeg.exe"
$framesDir = Join-Path $scriptRoot "frames"
$outputDir = Join-Path $scriptRoot "output"
if (-not $OutputPath) { $OutputPath = Join-Path $outputDir "MR60BHA2_research_promo.mp4" }
if (-not (Test-Path -LiteralPath $ffmpeg)) {
    Write-Host "FFmpeg is missing; running the project-local video setup..."
    & (Join-Path $scriptRoot "setup-video.ps1")
}
if (-not (Test-Path -LiteralPath $ffmpeg)) { throw "Missing encoder after setup: $ffmpeg" }
New-Item -ItemType Directory -Force -Path $framesDir, $outputDir | Out-Null
Get-ChildItem -LiteralPath $framesDir -Filter "frame_*.png" -File -ErrorAction SilentlyContinue | Remove-Item -Force

$fontRegular = "C:\Windows\Fonts\segoeui.ttf"
$fontBold = "C:\Windows\Fonts\segoeuib.ttf"
$fontMono = "C:\Windows\Fonts\consola.ttf"
$privateFonts = New-Object System.Drawing.Text.PrivateFontCollection
$privateFonts.AddFontFile($fontRegular)
$privateFonts.AddFontFile($fontBold)
$privateFonts.AddFontFile($fontMono)
$regularFamily = $privateFonts.Families | Where-Object { $_.Name -like "Segoe UI*" } | Select-Object -First 1
$monoFamily = $privateFonts.Families | Where-Object { $_.Name -like "Consolas*" } | Select-Object -First 1
if (-not $regularFamily) { $regularFamily = [System.Drawing.FontFamily]::GenericSansSerif }
if (-not $monoFamily) { $monoFamily = [System.Drawing.FontFamily]::GenericMonospace }

function C([string]$hex, [int]$alpha = 255) {
    $h = $hex.TrimStart('#')
    return [System.Drawing.Color]::FromArgb($alpha, [Convert]::ToInt32($h.Substring(0,2),16), [Convert]::ToInt32($h.Substring(2,2),16), [Convert]::ToInt32($h.Substring(4,2),16))
}
function F([float]$size, [bool]$bold = $false, [bool]$mono = $false) {
    $fam = if ($mono) { $monoFamily } else { $regularFamily }
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    return New-Object System.Drawing.Font($fam, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}
function Clamp01([double]$x) { return [Math]::Max(0, [Math]::Min(1, $x)) }
function Ease([double]$x) { $v = Clamp01 $x; return 1 - [Math]::Pow(1-$v, 3) }
function Fade([double]$t, [double]$start, [double]$end, [double]$fade = 0.55) {
    $a = Clamp01 (($t-$start)/$fade)
    $b = Clamp01 (($end-$t)/$fade)
    return [Math]::Min($a,$b)
}
function Brush([string]$hex, [int]$alpha = 255) { return New-Object System.Drawing.SolidBrush (C $hex $alpha) }
function Pen([string]$hex, [float]$width = 1, [int]$alpha = 255) { return New-Object System.Drawing.Pen (C $hex $alpha), $width }

function RoundRectPath([float]$x,[float]$y,[float]$w,[float]$h,[float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2*$r
    $p.AddArc($x,$y,$d,$d,180,90); $p.AddArc($x+$w-$d,$y,$d,$d,270,90)
    $p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90); $p.AddArc($x,$y+$h-$d,$d,$d,90,90)
    $p.CloseFigure(); return $p
}
function FillRound($g,[float]$x,[float]$y,[float]$w,[float]$h,[float]$r,[string]$fill,[int]$alpha=255,[string]$stroke="",[int]$strokeAlpha=255) {
    $p = RoundRectPath $x $y $w $h $r
    $b = Brush $fill $alpha; $g.FillPath($b,$p); $b.Dispose()
    if ($stroke) { $pn = Pen $stroke 1 $strokeAlpha; $g.DrawPath($pn,$p); $pn.Dispose() }
    $p.Dispose()
}
function Text($g,[string]$value,[float]$x,[float]$y,[float]$size,[string]$color,[bool]$bold=$false,[int]$alpha=255,[bool]$mono=$false,[string]$align="Near") {
    $font = F $size $bold $mono; $b = Brush $color $alpha
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::$align
    $g.DrawString($value,$font,$b,[System.Drawing.PointF]::new($x,$y),$sf)
    $sf.Dispose(); $b.Dispose(); $font.Dispose()
}
function Line($g,[float]$x1,[float]$y1,[float]$x2,[float]$y2,[string]$color,[float]$width=1,[int]$alpha=255) {
    $p = Pen $color $width $alpha; $p.StartCap = $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($p,$x1,$y1,$x2,$y2); $p.Dispose()
}
function Dot($g,[float]$x,[float]$y,[float]$r,[string]$color,[int]$alpha=255) {
    $b=Brush $color $alpha; $g.FillEllipse($b,$x-$r,$y-$r,2*$r,2*$r); $b.Dispose()
}
function DrawBackground($g,[double]$t) {
    $rect = [System.Drawing.Rectangle]::new(0,0,$Width,$Height)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,(C "07110F"),(C "0A1714"),35)
    $g.FillRectangle($grad,$rect); $grad.Dispose()
    $grid = Pen "24443C" 1 32
    $offset = [int](($t*7)%40)
    for($x=-40+$offset;$x -lt $Width;$x+=40){$g.DrawLine($grid,$x,0,$x,$Height)}
    for($y=-40+$offset;$y -lt $Height;$y+=40){$g.DrawLine($grid,0,$y,$Width,$y)}
    $grid.Dispose()
    $vignette = New-Object System.Drawing.Drawing2D.GraphicsPath
    $vignette.AddEllipse(-180,-260,$Width+360,$Height+520)
    $pg = New-Object System.Drawing.Drawing2D.PathGradientBrush($vignette)
    $pg.CenterColor = C "07110F" 0; $pg.SurroundColors = @(C "010403" 180)
    $g.FillRectangle($pg,$rect); $pg.Dispose(); $vignette.Dispose()
}
function DrawTopBar($g,[double]$t,[string]$section) {
    Text $g "MR60BHA2" 50 28 22 "D6FFF2" $true
    Text $g "60 GHz HUMAN SENSING" 196 34 11 "77A99B" $false 255 $true
    Dot $g 902 42 4 "6CF7C6"
    Text $g "SYSTEM ONLINE" 914 32 12 "6CF7C6" $true 255 $true
    Text $g $section 1230 32 12 "91BFB2" $false 255 $true "Far"
    Line $g 50 68 1230 68 "29483F" 1 170
}
function DrawRadar($g,[double]$t,[float]$cx,[float]$cy,[float]$radius,[double]$targetAngle=0.15,[double]$targetRange=0.58,[double]$alpha=1) {
    $a=[int](255*$alpha)
    $fan = New-Object System.Drawing.Drawing2D.GraphicsPath
    $fan.AddPie($cx-$radius,$cy-$radius,2*$radius,2*$radius,208,124)
    $fanBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($fan)
    $fanBrush.CenterPoint=[System.Drawing.PointF]::new($cx,$cy)
    $fanBrush.CenterColor=C "53F1B7" ([int](34*$alpha)); $fanBrush.SurroundColors=@(C "53F1B7" 0)
    $g.FillPath($fanBrush,$fan); $fanBrush.Dispose(); $fan.Dispose()
    for($i=1;$i -le 4;$i++){
        $r=$radius*$i/4; $p=Pen "60DCAF" 1 ([int](70*$alpha))
        $g.DrawArc($p,$cx-$r,$cy-$r,2*$r,2*$r,208,124);$p.Dispose()
        Text $g ("{0:0.0} m" -f (1.5*$i)) ($cx+8) ($cy-$r+5) 10 "6D9D91" $false ([int](180*$alpha)) $true
    }
    foreach($deg in 208,239,270,301,332){
        $rad=$deg*[Math]::PI/180; Line $g $cx $cy ($cx+$radius*[Math]::Cos($rad)) ($cy+$radius*[Math]::Sin($rad)) "60DCAF" 1 ([int](55*$alpha))
    }
    $sweepDeg=208+(($t*46)%124); $sr=$sweepDeg*[Math]::PI/180
    Line $g $cx $cy ($cx+$radius*[Math]::Cos($sr)) ($cy+$radius*[Math]::Sin($sr)) "8FFFD6" 2 ([int](190*$alpha))
    $ang=(270+$targetAngle*52)*[Math]::PI/180
    $tx=$cx+$radius*$targetRange*[Math]::Cos($ang); $ty=$cy+$radius*$targetRange*[Math]::Sin($ang)
    for($j=3;$j -ge 1;$j--){ Dot $g $tx $ty (6+$j*6+4*[Math]::Sin($t*3-$j)) "65F6C1" ([int](22*$j*$alpha)) }
    Dot $g $tx $ty 6 "D7FFF1" ([int](255*$alpha)); Dot $g $tx $ty 3 "52F2B7" ([int](255*$alpha))
    Text $g "TARGET 01" ($tx+18) ($ty-25) 11 "C9FFEC" $true ([int](255*$alpha)) $true
    Text $g ("1.{0:00} m" -f (18+4*[Math]::Sin($t*.7))) ($tx+18) ($ty-8) 11 "6CF7C6" $false ([int](230*$alpha)) $true
    FillRound $g ($cx-33) ($cy-14) 66 28 14 "12372E" ([int](230*$alpha)) "58E8B5" ([int](120*$alpha))
    Text $g "SENSOR" $cx ($cy-9) 10 "B8FFEA" $true ([int](255*$alpha)) $true "Center"
}
function DrawMetricCard($g,[float]$x,[float]$y,[float]$w,[float]$h,[string]$label,[string]$value,[string]$unit,[string]$accent,[string]$status,[double]$alpha=1) {
    $a=[int](255*$alpha)
    FillRound $g $x $y $w $h 16 "0E201C" ([int](235*$alpha)) "244D42" ([int](190*$alpha))
    Dot $g ($x+24) ($y+24) 5 $accent ([int](255*$alpha))
    Text $g $label ($x+38) ($y+13) 11 "83A99F" $true $a $true
    Text $g $value ($x+20) ($y+45) 31 "E5FFF6" $true $a $true
    Text $g $unit ($x+20+[Math]::Max(52,$value.Length*20)) ($y+62) 11 "7DA89C" $false $a $true
    Text $g $status ($x+$w-18) ($y+69) 10 $accent $true $a $true "Far"
}
function DrawSpark($g,[float]$x,[float]$y,[float]$w,[float]$h,[double]$t,[string]$color,[double]$freq=1,[double]$amp=1,[int]$alpha=255) {
    $pts = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    for($i=0;$i -le 100;$i++){
        $xx=$x+$w*$i/100
        $phase=($i/100*9+$t*$freq)*2*[Math]::PI
        $signal=[Math]::Sin($phase)*.55+[Math]::Sin($phase*2.1+.7)*.18+[Math]::Sin($phase*.37)*.1
        $yy=$y+$h/2-$signal*$h*.38*$amp
        $pts.Add([System.Drawing.PointF]::new($xx,$yy))
    }
    $p=Pen $color 2 $alpha; $g.DrawLines($p,$pts.ToArray());$p.Dispose()
}
function DrawDashboard($g,[double]$t,[double]$alpha) {
    DrawTopBar $g $t "LIVE / DEMO DATA"
    FillRound $g 48 93 690 548 20 "0B1C18" ([int](220*$alpha)) "254B41" ([int](180*$alpha))
    Text $g "SPATIAL PRESENCE" 74 116 12 "87B3A7" $true ([int](255*$alpha)) $true
    FillRound $g 555 108 154 28 14 "15362D" ([int](220*$alpha)) "397C67" ([int](160*$alpha))
    Dot $g 576 122 4 "62F3BC" ([int](255*$alpha))
    Text $g "1 HUMAN DETECTED" 588 114 10 "B8FFE7" $true ([int](255*$alpha)) $true
    DrawRadar $g $t 390 584 390 0.06 0.63 $alpha
    DrawMetricCard $g 766 94 220 124 "PRESENCE" "YES" "" "64F5BD" "CONF. 96%" $alpha
    $heart=[int](76+2*[Math]::Sin($t*.8)); DrawMetricCard $g 1004 94 226 124 "HEART RATE" "$heart" "BPM" "FF778B" "STABLE" $alpha
    $breath=[int](15+[Math]::Sin($t*.45)); DrawMetricCard $g 766 236 220 124 "BREATHING" "$breath" "RPM" "6DBEFF" "REGULAR" $alpha
    DrawMetricCard $g 1004 236 226 124 "DISTANCE" ("1.{0:00}" -f (18+4*[Math]::Sin($t*.7))) "M" "F6D472" "IN RANGE" $alpha
    FillRound $g 766 378 464 169 16 "0E201C" ([int](235*$alpha)) "244D42" ([int](190*$alpha))
    Text $g "MICRO-MOTION PHASE" 788 396 11 "83A99F" $true ([int](255*$alpha)) $true
    Text $g "LIVE" 1207 396 10 "61F1BA" $true ([int](255*$alpha)) $true "Far"
    for($i=0;$i -lt 4;$i++){Line $g 788 (438+$i*27) 1208 (438+$i*27) "2A4A42" 1 ([int](100*$alpha))}
    DrawSpark $g 788 429 420 96 $t "72F5C3" 0.52 1 ([int](230*$alpha))
    FillRound $g 766 565 464 76 16 "10241F" ([int](235*$alpha)) "2A594C" ([int](190*$alpha))
    Text $g "TARGET 01" 790 581 11 "B9FFE8" $true ([int](255*$alpha)) $true
    Text $g "Single-person vital-sign mode" 790 603 11 "789E94" $false ([int](255*$alpha))
    Text $g "TRACKED" 1207 592 11 "61F1BA" $true ([int](255*$alpha)) $true "Far"
}
function DrawIntro($g,[double]$t,[double]$alpha) {
    DrawTopBar $g $t "RESEARCH PROTOTYPE"
    $rise=Ease (($t-.3)/1.1)
    Text $g "NON-CONTACT" 78 (176+20*(1-$rise)) 16 "6CF7C6" $true ([int](240*$alpha)) $true
    Text $g "HUMAN SENSING" 74 (205+28*(1-$rise)) 54 "E5FFF6" $true ([int](255*$alpha))
    Text $g "WITH 60 GHz mmWAVE RADAR" 78 (274+28*(1-$rise)) 22 "86BCAE" $false ([int](255*$alpha)) $true
    Text $g "Presence  /  Micro-motion  /  Vital signs" 79 330 15 "A9CCC2" $false ([int](220*$alpha))
    FillRound $g 78 381 274 44 22 "12362D" ([int](210*$alpha)) "4BC296" ([int](170*$alpha))
    Dot $g 102 403 5 "65F7C0" ([int](255*$alpha)); Text $g "REAL-TIME PERCEPTION" 118 392 12 "C4FFEC" $true ([int](255*$alpha)) $true
    DrawRadar $g $t 935 631 390 0.02 0.60 $alpha
    Text $g "DEMO DATA" 78 614 10 "68988C" $true ([int](210*$alpha)) $true
    Text $g "MR60BHA2 SENSOR PLATFORM" 78 636 11 "7CAC9F" $false ([int](220*$alpha)) $true
}
function DrawSignalScene($g,[double]$t,[double]$alpha) {
    DrawTopBar $g $t "SIGNAL ANALYSIS"
    Text $g "MICRO-MOTION" 60 108 15 "6CF7C6" $true ([int](255*$alpha)) $true
    Text $g "FROM PHASE TO INSIGHT" 58 138 38 "E1FFF5" $true ([int](255*$alpha))
    Text $g "Subtle chest displacement modulates the reflected radar phase." 60 194 15 "94BDB2" $false ([int](240*$alpha))
    FillRound $g 58 240 755 360 18 "0C1E19" ([int](235*$alpha)) "284E44" ([int](190*$alpha))
    Text $g "RAW PHASE SIGNAL" 84 263 11 "7EA79C" $true ([int](255*$alpha)) $true
    for($i=0;$i -lt 7;$i++){Line $g 84 (310+$i*40) 784 (310+$i*40) "28483F" 1 ([int](105*$alpha))}
    DrawSpark $g 84 300 700 230 $t "6CF7C6" 0.36 1 ([int](245*$alpha))
    $cursorX=84+700*(($t*.22)%1); Line $g $cursorX 300 $cursorX 548 "D9FFF3" 1 ([int](150*$alpha)); Dot $g $cursorX (415+52*[Math]::Sin(($cursorX-84)/700*18*[Math]::PI+$t*2)) 4 "ECFFF9" ([int](250*$alpha))
    Text $g "TIME" 784 561 10 "648B81" $false ([int](230*$alpha)) $true "Far"
    $items=@(@("PRESENCE","Detected","64F5BD"),@("HEART RATE","76 BPM","FF778B"),@("BREATHING","15 RPM","6DBEFF"))
    for($i=0;$i -lt 3;$i++){
        $yy=250+$i*116; FillRound $g 846 $yy 376 92 14 "10231E" ([int](235*$alpha)) "285045" ([int](180*$alpha))
        Dot $g 873 ($yy+28) 5 $items[$i][2] ([int](255*$alpha)); Text $g $items[$i][0] 890 ($yy+18) 11 "82A99F" $true ([int](255*$alpha)) $true
        Text $g $items[$i][1] 1196 ($yy+44) 25 "E4FFF6" $true ([int](255*$alpha)) $true "Far"
    }
    Text $g "DEMO DATA / SINGLE TARGET" 846 611 10 "648F84" $true ([int](225*$alpha)) $true
}
function DrawRobotScene($g,[double]$t,[double]$alpha) {
    DrawTopBar $g $t "ROBOT INTEGRATION"
    Text $g "HUMAN-AWARE ROBOTICS" 640 112 39 "E4FFF6" $true ([int](255*$alpha)) $false "Center"
    Text $g "A privacy-preserving perception layer for responsive machines" 640 164 15 "91B9AE" $false ([int](240*$alpha)) $false "Center"
    $nodes=@(@(110,"60 GHz RADAR","Presence + motion"),@(470,"EDGE PROCESSING","Filter + interpret"),@(830,"ROBOT RESPONSE","Adapt + assist"))
    for($i=0;$i -lt 3;$i++){
        $delay=$i*.22; $grow=Ease (($t-19-$delay)/.7); $x=[float]$nodes[$i][0]; $w=300*$grow
        FillRound $g ($x+(300-$w)/2) 270 $w 168 18 "10251F" ([int](235*$alpha)) "3B806B" ([int](210*$alpha))
        if($grow -gt .7){
            $iconX=$x+150; $iconY=313
            Dot $g $iconX $iconY 22 "173E33" ([int](240*$alpha)); Dot $g $iconX $iconY 6 "69F4BD" ([int](255*$alpha))
            if($i -eq 0){for($q=1;$q -le 3;$q++){ $p=Pen "69F4BD" 1 ([int](100*$alpha));$g.DrawArc($p,$iconX-10-$q*8,$iconY-10-$q*8,20+$q*16,20+$q*16,205,130);$p.Dispose()}}
            elseif($i -eq 1){for($q=-1;$q -le 1;$q++){Line $g ($iconX-24) ($iconY+$q*12) ($iconX+24) ($iconY+$q*12) "69F4BD" 2 ([int](170*$alpha))}}
            else{FillRound $g ($iconX-20) ($iconY-18) 40 36 8 "173E33" 255 "69F4BD" ([int](210*$alpha)); Dot $g ($iconX-8) ($iconY-2) 3 "69F4BD";Dot $g ($iconX+8) ($iconY-2) 3 "69F4BD"}
            Text $g $nodes[$i][1] ($x+150) 360 14 "D8FFF1" $true ([int](255*$alpha)) $true "Center"
            Text $g $nodes[$i][2] ($x+150) 390 12 "7FA99E" $false ([int](230*$alpha)) $false "Center"
        }
        if($i -lt 2){
            $pulse=(($t*.8+$i*.34)%1); Line $g ($x+310) 354 ($x+350) 354 "3A715F" 2 ([int](180*$alpha)); Dot $g ($x+310+40*$pulse) 354 4 "76F7C6" ([int](255*$alpha))
        }
    }
    $tags=@("CONTACTLESS","LOW-LIGHT READY","PRIVACY AWARE","REAL-TIME")
    for($i=0;$i -lt $tags.Count;$i++){ $x=190+$i*232; FillRound $g $x 490 202 38 19 "112F27" ([int](215*$alpha)) "316855" ([int](160*$alpha)); Text $g $tags[$i] ($x+101) 501 10 "AFFFF0" $true ([int](255*$alpha)) $true "Center" }
    Text $g "Research prototype / Validate performance in the target environment" 640 604 11 "668E84" $false ([int](230*$alpha)) $false "Center"
}
function DrawOutro($g,[double]$t,[double]$alpha) {
    DrawTopBar $g $t "MR60BHA2"
    $pulse=.5+.5*[Math]::Sin($t*2)
    Dot $g 640 210 (42+4*$pulse) "173E33" ([int](230*$alpha)); Dot $g 640 210 13 "6CF7C6" ([int](255*$alpha))
    Text $g "SENSE PRESENCE." 640 285 36 "E5FFF6" $true ([int](255*$alpha)) $false "Center"
    Text $g "UNDERSTAND MOTION." 640 332 36 "E5FFF6" $true ([int](255*$alpha)) $false "Center"
    Text $g "ENABLE SAFER INTERACTION." 640 379 36 "6CF7C6" $true ([int](255*$alpha)) $false "Center"
    Text $g "60 GHz mmWave sensing for human-robot research" 640 455 16 "90B9AE" $false ([int](235*$alpha)) $false "Center"
    FillRound $g 510 515 260 42 21 "14372E" ([int](220*$alpha)) "4DBE96" ([int](170*$alpha))
    Text $g "RESEARCH PROTOTYPE" 640 527 11 "C7FFED" $true ([int](255*$alpha)) $true "Center"
    Text $g "Not a medical diagnostic device" 640 608 10 "5F857B" $false ([int](230*$alpha)) $true "Center"
}

$totalFrames=[int][Math]::Ceiling($Duration*$Fps)
for($frame=0;$frame -lt $totalFrames;$frame++){
    $t=$frame/$Fps
    $bmp=New-Object System.Drawing.Bitmap($Width,$Height,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    DrawBackground $g $t
    if($t -lt 5.0){ DrawIntro $g $t (Fade $t 0 5.0 .7) }
    elseif($t -lt 13.5){ DrawDashboard $g $t (Fade $t 5.0 13.5 .55) }
    elseif($t -lt 18.6){ DrawSignalScene $g $t (Fade $t 13.5 18.6 .55) }
    elseif($t -lt 22.0){ DrawRobotScene $g $t (Fade $t 18.6 22.0 .55) }
    else{ DrawOutro $g $t (Fade $t 22.0 24.0 .55) }
    $framePath=Join-Path $framesDir ("frame_{0:D5}.png" -f $frame)
    $bmp.Save($framePath,[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose();$bmp.Dispose()
    if(($frame%60)-eq 0){Write-Progress -Activity "Rendering radar promo" -Status "$frame / $totalFrames" -PercentComplete (100*$frame/$totalFrames)}
}
Write-Progress -Activity "Rendering radar promo" -Completed

$inputPattern=Join-Path $framesDir "frame_%05d.png"
$audio="0.010*sin(2*PI*58*t)*(0.65+0.35*sin(2*PI*0.18*t))+0.004*sin(2*PI*116*t)"
& $ffmpeg -y -framerate $Fps -i $inputPattern -f lavfi -i "aevalsrc=$audio`:s=48000`:d=$Duration" -vf "scale=1920:1080:flags=lanczos,format=yuv420p" -af "afade=t=in:st=0:d=1.2,afade=t=out:st=22.4:d=1.6" -c:v libx264 -preset medium -crf 18 -r $Fps -c:a aac -b:a 160k -shortest -movflags +faststart $OutputPath
if($LASTEXITCODE -ne 0){throw "Video encoding failed with exit code $LASTEXITCODE"}

$preview=Join-Path $outputDir "preview.png"
& $ffmpeg -y -ss 00:00:08.0 -i $OutputPath -frames:v 1 -update 1 $preview | Out-Null
if($LASTEXITCODE -ne 0){throw "Preview extraction failed"}

$resolvedFrames=[System.IO.Path]::GetFullPath($framesDir)
$resolvedRoot=[System.IO.Path]::GetFullPath($scriptRoot)
if($resolvedFrames.StartsWith($resolvedRoot,[System.StringComparison]::OrdinalIgnoreCase)){
    Get-ChildItem -LiteralPath $resolvedFrames -Filter "frame_*.png" -File | Remove-Item -Force
}
Write-Host "Video: $OutputPath"
Write-Host "Preview: $preview"
