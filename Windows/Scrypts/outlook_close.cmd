
@echo off
:: Пытаемся закрыть мягко (без /F)
taskkill /IM OUTLOOK.EXE > nul 2>&1

:: Ждем 3 секунды, чтобы процесс успел завершиться сам
timeout /t 3 /nobreak > nul

:: Если процесс все еще жив — убиваем принудительно
tasklist /FI "IMAGENAME eq OUTLOOK.EXE" | findstr /I "OUTLOOK.EXE" > nul
if %ERRORLEVEL%==0 (
    taskkill /F /IM OUTLOOK.EXE /T > nul
)

cls
echo "--------------- OK, Restarting... --------------------"
start "" "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"


exit 0
@echo off
taskkill /F /FI "ImageName eq OUTLOOK*" > nul
cls
echo "---------------OK--------------------"
pause
