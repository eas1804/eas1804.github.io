@echo off
cls
setlocal

set OVPN_PROFILE=Osipenko_04_2025.ovpn
set RDP_SERVER=10.10.10.3

set RETRIES=10
set WAIT_BETWEEN=3

set OVPN_GUI="C:\Program Files\OpenVPN\bin\openvpn-gui.exe"

echo Part 1. Connect to VPN...
%OVPN_GUI% --connect %OVPN_PROFILE%


rem  Циклическая проверка доступности сервера
set /a i=1
:ping_loop
echo part 2. Test connect %RDP_SERVER% (step %i% from %RETRIES%)...
ping -n 2 %RDP_SERVER% >nul
if not errorlevel 1 (
    echo Part 3. Start  RDP...
    start /wait mstsc /v:%RDP_SERVER% /f
    goto disconnect_vpn
)

if %i% GEQ %RETRIES% (
    echo Сервер недоступен после %RETRIES% попыток. Отключение VPN...
    goto disconnect_vpn
)

set /a i+=1
timeout /t %WAIT_BETWEEN% /nobreak >nul
goto ping_loop

:disconnect_vpn
echo Отключение VPN...
%OVPN_GUI% --command disconnect_all

endlocal
exit /b
