$ErrorActionPreference = 'Continue'
$adb = 'D:\ProGram\Libs\platform-tools\adb.exe'
$emu = 'C:\Users\HUI\AppData\Local\Android\sdk\emulator\emulator.exe'
$debugApk = 'D:\ProGram\MoodDairy\emotiondairy\build\app\outputs\flutter-apk\app-debug.apk'
$prefs = 'D:\ProGram\MoodDairy\tools\FlutterSharedPreferences.xml'
$pkg = 'com.example.emotiondairy'
$out = 'D:\ProGram\MoodDairy\store-assets\_raw'
New-Item -ItemType Directory -Force -Path $out | Out-Null

function Shot([string]$name) {
  $p = Join-Path $out "$name.png"
  cmd /c "`"$adb`" exec-out screencap -p > `"$p`""
  if (Test-Path $p) { $sz = (Get-Item $p).Length; "shot $name : $sz bytes" } else { "shot $name FAILED" }
}

Start-Process -FilePath $emu -WindowStyle Hidden `
  -ArgumentList '-avd','Medium_Phone_API_37.0','-no-window','-no-audio','-no-boot-anim','-no-snapshot','-gpu','swiftshader_indirect' `
  -RedirectStandardOutput (Join-Path $out 'emu.out.log') `
  -RedirectStandardError (Join-Path $out 'emu.err.log')

$booted = $false
for ($i = 0; $i -lt 100; $i++) {
  $b = (& $adb shell getprop sys.boot_completed 2>$null | Out-String).Trim()
  if ($b -eq '1') { $booted = $true; break }
  Start-Sleep -Seconds 5
}
"booted=$booted after $($i * 5)s"
if (-not $booted) { exit 1 }

# 9:16 canvas
& $adb shell wm size 1080x1920 | Out-Null
& $adb shell wm density 420 | Out-Null
& $adb shell settings put global window_animation_scale 0 | Out-Null
& $adb shell settings put global transition_animation_scale 0 | Out-Null
& $adb shell settings put global animator_duration_scale 0 | Out-Null
Start-Sleep -Seconds 3
"size=" + (& $adb shell wm size | Out-String).Trim()

& $adb uninstall $pkg 2>&1 | Out-Null
(& $adb install -r $debugApk 2>&1 | Out-String).Trim()
& $adb shell am start -n "$pkg/.MainActivity" | Out-Null
Start-Sleep -Seconds 10

Shot 'empty-01-home'
& $adb shell input tap 539 1745 | Out-Null; Start-Sleep -Seconds 2; Shot 'empty-02-trends'
& $adb shell input tap 864 1745 | Out-Null; Start-Sleep -Seconds 2; Shot 'empty-03-history'
& $adb shell input tap 215 1745 | Out-Null; Start-Sleep -Seconds 2
& $adb shell input tap 971 155 | Out-Null; Start-Sleep -Seconds 2; Shot 'empty-04-profile'
& $adb shell input keyevent 4 | Out-Null; Start-Sleep -Seconds 1

# Inject illustrative entries for the marketing shots.
& $adb shell am force-stop $pkg | Out-Null
& $adb push $prefs /data/local/tmp/mood_prefs.xml 2>&1 | Out-Null
& $adb shell "run-as $pkg mkdir -p shared_prefs" 2>&1 | Out-Null
$copy = & $adb shell "run-as $pkg sh -c 'cat /data/local/tmp/mood_prefs.xml > shared_prefs/FlutterSharedPreferences.xml'" 2>&1 | Out-String
"copy: $($copy.Trim())"
$check = & $adb shell "run-as $pkg sh -c 'wc -c shared_prefs/FlutterSharedPreferences.xml'" 2>&1 | Out-String
"prefs size: $($check.Trim())"

& $adb shell am start -n "$pkg/.MainActivity" | Out-Null
Start-Sleep -Seconds 12

Shot '01-home'
& $adb shell input tap 539 1745 | Out-Null; Start-Sleep -Seconds 3; Shot '02-trends'
& $adb shell input tap 864 1745 | Out-Null; Start-Sleep -Seconds 3; Shot '03-history'
& $adb shell input tap 215 1745 | Out-Null; Start-Sleep -Seconds 2
& $adb shell input tap 971 155 | Out-Null; Start-Sleep -Seconds 3; Shot '04-profile'

'--- flutter logcat ---'
(& $adb logcat -d -s flutter:E AndroidRuntime:E 2>&1 | Select-Object -Last 15 | Out-String)

& $adb emu kill 2>&1 | Out-Null
exit 0
