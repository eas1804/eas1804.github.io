# Ввод имени пользователя
$UserName = Read-Host "Введите имя пользователя"

# Временный пароль
$TempPassword = "Temp@123"

# Создать пользователя
if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
    $sec = ConvertTo-SecureString $TempPassword -AsPlainText -Force
    New-LocalUser -Name $UserName -Password $sec -FullName $UserName -Description "RDP User" -UserMayNotChangePassword:$false
    Write-Host "User $UserName created"
} else {
    Write-Host "User $UserName already exists"
}

# Добавить в группу "Remote Desktop Users" (SID S-1-5-32-555)
$rdpSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-555")
$rdpName = ($rdpSid.Translate([System.Security.Principal.NTAccount]).Value.Split("\\"))[1]
Add-LocalGroupMember -Group $rdpName -Member $UserName
Write-Host "Added to group $rdpName"

# Добавить в группу "Users" (SID S-1-5-32-545)
$usersSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-545")
$usersName = ($usersSid.Translate([System.Security.Principal.NTAccount]).Value.Split("\\"))[1]
Add-LocalGroupMember -Group $usersName -Member $UserName
Write-Host "Added to group $usersName"

# НЕ ставим PasswordExpired — иначе RDP не даст сменить пароль

# Итог
Get-LocalUser -Name $UserName | Select-Object Name, Enabled, Description
