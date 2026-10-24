$ErrorActionPreference = 'Continue'
$adb = 'D:\ProGram\Libs\platform-tools\adb.exe'
$emu = 'C:\Users\HUI\AppData\Local\Android\sdk\emulator\emulator.exe'
$pkg = 'com.example.emotiondairy'
$out = 'D:\ProGram\MoodDairy\store-assets\_raw2'
New-Item -ItemType Directory -Force -Path $out | Out-Null

function Shot([string]$name) {
  $p = Join-Path $out "$name.png"
  cmd /c "`"$adb`" exec-out screencap -p > `"$p`""
  "shot $name : $((Get-Item $p).Length) bytes"
}

Start-Process -FilePath $emu -WindowStyle Hidden `
  -ArgumentList '-avd','Medium_Phone_API_37.0','-no-window','-no-audio','-no-boot-anim','-no-snapshot','-gpu','swiftshader_indirect' `
  -RedirectStandardOutput (Join-Path $out 'emu.out.log') `
  -RedirectStandardError (Join-Path $out 'emu.err.log')

for ($i = 0; $i -lt 120; $i++) {
  if ((((& $adb shell getprop sys.boot_completed 2>$null) | Out-String).Trim()) -eq '1') { break }
  Start-Sleep -Seconds 5
}
"booted after $($i * 5)s"
Start-Sleep -Seconds 45

# Dismiss any "isn't responding" dialogs left by the boot storm.
& $adb shell input keyevent 4 | Out-Null
& $adb shell input keyevent 4 | Out-Null
Start-Sleep -Seconds 3

& $adb shell wm size 1080x1920 | Out-Null
& $adb shell wm density 384 | Out-Null
& $adb shell settings put global window_animation_scale 0 | Out-Null
& $adb shell settings put global transition_animation_scale 0 | Out-Null
& $adb shell settings put global animator_duration_scale 0 | Out-Null
Start-Sleep -Seconds 25

& $adb shell am force-stop $pkg | Out-Null
Start-Sleep -Seconds 2
& $adb shell am start -n "$pkg/.MainActivity" | Out-Null
Start-Sleep -Seconds 15
"focus: " + ((& $adb shell "dumpsys window | grep -m1 mCurrentFocus" 2>$null) | Out-String).Trim()

Shot 'd384-01-home'
& $adb shell input tap 539 1800 | Out-Null; Start-Sleep -Seconds 3; Shot 'd384-02-trends'
& $adb shell input tap 864 1800 | Out-Null; Start-Sleep -Seconds 3; Shot 'd384-03-history'
& $adb shell input tap 215 1800 | Out-Null; Start-Sleep -Seconds 2
& $adb shell input tap 971 150 | Out-Null; Start-Sleep -Seconds 3; Shot 'd384-04-profile'
exit 0
