# 卸载：删除启动快捷方式和脚本目录
$ErrorActionPreference = 'Stop'

$startup = [Environment]::GetFolderPath('Startup')
$appDir  = Join-Path $env:LOCALAPPDATA 'AutoDial'
$removed = 0

foreach ($f in @((Join-Path $startup 'AutoDial.lnk'), (Join-Path $startup 'AutoDial.vbs'))) {
    if (Test-Path $f) { Remove-Item -LiteralPath $f -Force; Write-Host "已删除: $f"; $removed++ }
}

if (Test-Path $appDir) {
    Remove-Item -LiteralPath $appDir -Recurse -Force
    Write-Host "已删除: $appDir"
    $removed++
}

if ($removed -eq 0) { Write-Host '未安装，无需卸载。' } else { Write-Host '卸载完成。' }
