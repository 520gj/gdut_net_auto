# 卸载：从「启动」文件夹删除 AutoDial.vbs
$ErrorActionPreference = 'Stop'

$dst = Join-Path ([Environment]::GetFolderPath('Startup')) 'AutoDial.vbs'

if (Test-Path $dst) {
    Remove-Item -LiteralPath $dst -Force
    Write-Host "已删除: $dst"
} else {
    Write-Host "未安装（$dst 不存在）"
}
