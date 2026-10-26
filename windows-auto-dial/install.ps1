# 安装：把 AutoDial.vbs 放进当前用户的「启动」文件夹
$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'AutoDial.vbs'
$dstDir = [Environment]::GetFolderPath('Startup')
$dst = Join-Path $dstDir 'AutoDial.vbs'

if (-not (Test-Path $src)) { throw "AutoDial.vbs not found next to this script." }

Copy-Item -LiteralPath $src -Destination $dst -Force
Write-Host "已安装到: $dst"
Write-Host "登录 Windows 后会自动拨号；取消请运行 uninstall.ps1"
Write-Host ""
Write-Host "提示: 请用记事本打开 AutoDial.vbs，把开头的 CONN 改成你自己的拨号连接名。"
Write-Host "      若脚本报 691，说明 Windows 里没保存密码，请手动拨号一次并勾选「记住密码」。"
