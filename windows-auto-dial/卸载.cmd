@echo off
setlocal
echo ===== kdlink 开机自动拨号 - 卸载 =====
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$l=Join-Path ([Environment]::GetFolderPath('Startup')) 'AutoDial.lnk'; $d=Join-Path $env:LOCALAPPDATA 'AutoDial'; $legacy=Join-Path ([Environment]::GetFolderPath('Startup')) 'AutoDial.vbs'; $n=0; if(Test-Path $l){ Remove-Item -LiteralPath $l -Force; Write-Host ('已删除 ' + $l); $n++ }; if(Test-Path $legacy){ Remove-Item -LiteralPath $legacy -Force; Write-Host ('已删除 ' + $legacy); $n++ }; if(Test-Path $d){ Remove-Item -LiteralPath $d -Recurse -Force; Write-Host ('已删除 ' + $d); $n++ }; if($n -eq 0){ Write-Host '未安装，无需卸载。' } else { Write-Host ''; Write-Host '卸载完成：下次登录不会再自动拨号。' -ForegroundColor Green; Write-Host '当前已连接的拨号不受影响。' }"
echo.
pause