

@chcp 65001 >nul
@echo off
set PORT=22
set REMOTE_HOST=backup12345.backup.1cloudlab.com
set REMOTE_USER=backup12345
set REMOTE_PATH=/backup/restic/nester4uk/
set SSH_KEY_PATH=C:/Users/us/colocall.key
set RESTIC_PASSWORD_FILE=C:/Users/us/restic-password.txt

set FROM="D:\Бух"
set TAG=BUH
restic -r sftp:%REMOTE_USER%@%REMOTE_HOST%:%REMOTE_PATH% -o "sftp.command=ssh -i %SSH_KEY_PATH% -p %PORT% -o StrictHostKeyChecking=no %REMOTE_USER%@%REMOTE_HOST% -s sftp"  backup  %FROM% --tag=%TAG%


pause