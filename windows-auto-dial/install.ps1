# 安装：脚本放到 %LOCALAPPDATA%\AutoDial，并在「启动」文件夹里建快捷方式
#
# 为什么不直接把 .vbs 丢进启动文件夹：
#   Windows 11 已把 VBScript 列为弃用组件，裸 .vbs 放在启动文件夹里
#   可能根本不会被执行。快捷方式（.lnk）才是系统认可的启动项形式。
$ErrorActionPreference = 'Stop'

$src     = Join-Path $PSScriptRoot 'AutoDial.vbs'
$appDir  = Join-Path $env:LOCALAPPDATA 'AutoDial'
$script  = Join-Path $appDir 'AutoDial.vbs'
$startup = [Environment]::GetFolderPath('Startup')
$lnkPath = Join-Path $startup 'AutoDial.lnk'

if (-not (Test-Path $src)) { throw "AutoDial.vbs 不在 install.ps1 旁边，请在同一目录运行。" }

New-Item -ItemType Directory -Path $appDir -Force | Out-Null
Copy-Item -LiteralPath $src -Destination $script -Force

$ws  = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut($lnkPath)
$lnk.TargetPath       = "$env:WINDIR\System32\wscript.exe"
$lnk.Arguments        = '"' + $script + '"'
$lnk.WorkingDirectory = $appDir
$lnk.Description      = 'kdlink 开机自动拨号'
$lnk.WindowStyle      = 7
$lnk.Save()

# 清理旧版安装方式：直接放在启动文件夹里的 .vbs
$legacy = Join-Path $startup 'AutoDial.vbs'
if (Test-Path $legacy) { Remove-Item -LiteralPath $legacy -Force }

Write-Host "脚本位置  : $script"
Write-Host "启动快捷方式: $lnkPath"
Write-Host ""
Write-Host "登录 Windows 后会自动拨号；取消请运行 uninstall.ps1"
Write-Host "提示: 请用记事本打开脚本，把开头的 CONN 改成你自己的拨号连接名；"
Write-Host "      若脚本报 691，说明 Windows 里没保存密码，请手动拨号一次并勾选「记住密码」。"
