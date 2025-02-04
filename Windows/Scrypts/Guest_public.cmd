echo "зайти на сетевую шару где нет авторизаци"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1
net stop LanmanWorkstation && net start LanmanWorkstation