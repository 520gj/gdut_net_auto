# 安装：脚本放到 %LOCALAPPDATA%\AutoDial，并在「启动」文件夹里建快捷方式
#
# 为什么不直接把 .vbs 丢进启动文件夹：
#   Windows 11 已把 VBScript 列为弃用组件，裸 .vbs 放在启动文件夹里
#   可能根本不会被执行。快捷方式（.lnk）才是系统认可的启动项形式。
#
# 重装说明：
#   如果部署版里已经填好了账号密码，重装会自动沿用，不会被清空。
#   想强制覆盖成仓库里的空白版本，加 -Force。
#
# 用法：
#   .\install.ps1          正常安装 / 升级（保留已有账号密码）
#   .\install.ps1 -Force   强制覆盖（凭据会被清空）
param([switch]$Force)
$ErrorActionPreference = 'Stop'

$src     = Join-Path $PSScriptRoot 'AutoDial.vbs'
$appDir  = Join-Path $env:LOCALAPPDATA 'AutoDial'
$script  = Join-Path $appDir 'AutoDial.vbs'
$startup = [Environment]::GetFolderPath('Startup')
$lnkPath = Join-Path $startup 'AutoDial.lnk'

if (-not (Test-Path $src)) { throw "AutoDial.vbs 不在 install.ps1 旁边，请在同一目录运行。" }

# ---------- 保留已部署脚本里的账号密码 ----------
$keepUser = ''
$keepPass = ''
$hasCreds = $false

if ((Test-Path $script) -and -not $Force) {
    $old = Get-Content -LiteralPath $script -Raw
    if ($old -match '(?m)^Const\s+USERNAME\s*=\s*"([^"]*)"') { $keepUser = $Matches[1] }
    if ($old -match '(?m)^Const\s+PASSWORD\s*=\s*"([^"]*)"') { $keepPass = $Matches[1] }
    if ($keepUser -ne '' -or $keepPass -ne '') { $hasCreds = $true }
}

New-Item -ItemType Directory -Path $appDir -Force | Out-Null
Copy-Item -LiteralPath $src -Destination $script -Force

if ($hasCreds) {
    $u = $keepUser.Replace('"', '""')
    $p = $keepPass.Replace('"', '""')
    $lines = @(Get-Content -LiteralPath $script)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if     ($lines[$i] -match '^Const\s+USERNAME') { $lines[$i] = 'Const USERNAME   = "' + $u + '"   '' 沿用上次安装的账号' }
        elseif ($lines[$i] -match '^Const\s+PASSWORD') { $lines[$i] = 'Const PASSWORD   = "' + $p + '"   '' 沿用上次安装的密码' }
    }
    Set-Content -LiteralPath $script -Value $lines -Encoding Default
}

# ---------- 启动快捷方式 ----------
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

# ---------- 结果 ----------
Write-Host "脚本位置    : $script"
Write-Host "启动快捷方式: $lnkPath"
Write-Host ""
if ($hasCreds) {
    Write-Host "已沿用上次安装的账号密码。" -ForegroundColor Green
} else {
    Write-Host "注意：脚本里的 USERNAME / PASSWORD 还是空的。" -ForegroundColor Yellow
    Write-Host "      Windows 11 对 PPPoE 连接不会保存密码，不填会一直报 628。"
    Write-Host "      请用记事本打开上面的脚本，把这两行填上。"
}
Write-Host ""
Write-Host "登录 Windows 后会自动拨号；取消请运行 uninstall.ps1"
Write-Host "CONN 是拨号连接名，不是你的连接名就改一下。"
