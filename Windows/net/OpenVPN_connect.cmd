@echo off
setlocal

set OVPN_PROFILE=vpn_giaroom_com_TCP.ovpn
set RDP_SERVER=10.10.10.3

rem ниже Ничего не трогать
set OVPN_GUI="C:\Program Files\OpenVPN\bin\openvpn-gui.exe"
%OVPN_GUI% --command  disconnect %OVPN_PROFILE%
%OVPN_GUI% --connect %OVPN_PROFILE%

setlocal enabledelayedexpansion

for /l %%i in (1,1,10) do (
    ping -n 1 -w 1000 10.10.10.3 >nul
    if !errorlevel! == 0 (
        echo Attempt %%i: Server is UP
        start /wait mstsc /v:%RDP_SERVER% /f
        goto disconnect_vpn
    ) else (
        echo Attempt %%i: Wait %%i
    )
    timeout /t 1 >nul
)


:disconnect_vpn
%OVPN_GUI% --command  disconnect %OVPN_PROFILE%

endlocal
exit /b
