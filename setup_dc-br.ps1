# =============================================
# Вариант 19 — DC-BR (Windows Server 2019)
# IP         : 172.26.197.97/27
# Шлюз       : 172.26.197.126
# Домен      : br.right
# Пароль     : P@ssw0rd
# =============================================

# --- 1. Имя и IP ---
Rename-Computer -NewName "DC-BR" -Force

$iface = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
New-NetIPAddress -InterfaceAlias $iface.Name `
    -IPAddress "172.26.197.97" `
    -PrefixLength 27 `
    -DefaultGateway "172.26.197.126"
Set-DnsClientServerAddress -InterfaceAlias $iface.Name `
    -ServerAddresses "127.0.0.1","77.88.8.8"

# --- 2. Роли ---
Install-WindowsFeature -Name AD-Domain-Services, DHCP, DNS, FS-FileServer `
    -IncludeManagementTools

# --- 3. Домен br.right ---
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName "br.right" `
    -DomainNetbiosName "BR" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force) `
    -InstallDns:$true `
    -Force:$true

# После перезагрузки (войти как administrator@br.right):

# --- 4. DNS ---
Add-DnsServerForwarder -IPAddress "77.88.8.8"

Add-DnsServerPrimaryZone `
    -NetworkID "172.26.197.96/27" `
    -ReplicationScope "Domain"

Add-DnsServerResourceRecordA -ZoneName "br.right" -Name "fw-br" -IPv4Address "172.26.197.126" -CreatePtr
Add-DnsServerResourceRecordA -ZoneName "br.right" -Name "dc-br" -IPv4Address "172.26.197.97"  -CreatePtr

# --- 5. DHCP ---
# Диапазон: 172.26.197.98 – 172.26.197.105 (8 адресов, ≥30% от 28 свободных)
# Зарезервированы: .97 (DC-BR), .126 (FW-BR)

Add-DhcpServerv4Scope `
    -Name "BR_Local" `
    -StartRange "172.26.197.98" `
    -EndRange "172.26.197.105" `
    -SubnetMask "255.255.255.224" `
    -State Active

Set-DhcpServerv4OptionValue `
    -ScopeId "172.26.197.96" `
    -DnsServer "172.26.197.97" `
    -Router "172.26.197.126" `
    -DnsDomain "br.right"

Add-DhcpServerInDC -DnsName "dc-br.br.right" -IPAddress "172.26.197.97"

Write-Host "=== DC-BR настроен! ===" -ForegroundColor Green
