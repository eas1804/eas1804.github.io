# Ввод имени пользователя
$UserName = Read-Host "Введите имя пользователя"

# Временный пароль
$TempPassword = "Temp@123"

# Создать пользователя
if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
    $sec = ConvertTo-SecureString $TempPassword -AsPlainText -Force
    New-LocalUser -Name $UserName -Password $sec -FullName $UserName -Description "RDP User"
    Write-Host "User $UserName created"
} else {
    Write-Host "User $UserName already exists"
}

# Добавить в группу RDP (SID S-1-5-32-555)
$rdpSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-555")
$rdpName = ($rdpSid.Translate([System.Security.Principal.NTAccount]).Value.Split("\\"))[1]
Add-LocalGroupMember -Group $rdpName -Member $UserName
Write-Host "Added to group $rdpName"

# Требовать смену пароля при следующем входе
$adsiUser = [ADSI]("WinNT://$env:COMPUTERNAME/$UserName,user")
$adsiUser.Put("PasswordExpired", 1)
$adsiUser.SetInfo()
Write-Host "Password change required at next login"

# Итог
Get-LocalUser -Name $UserName | Select-Object Name, Enabled, Description
