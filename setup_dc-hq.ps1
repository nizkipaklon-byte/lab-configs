# =============================================
# Вариант 19 — DC-HQ (Windows Server 2019)
# IP         : 192.168.239.126/27
# Шлюз       : 192.168.239.97
# DNS        : 127.0.0.1 (после установки AD), 77.88.8.8 (форвардер)
# Домен      : hq.left
# Пароль     : P@ssw0rd
# =============================================
# Запускать в PowerShell от имени Администратора

# --- 1. Имя компьютера и IP ---
Rename-Computer -NewName "DC-HQ" -Force

$iface = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
New-NetIPAddress -InterfaceAlias $iface.Name `
    -IPAddress "192.168.239.126" `
    -PrefixLength 27 `
    -DefaultGateway "192.168.239.97"
Set-DnsClientServerAddress -InterfaceAlias $iface.Name `
    -ServerAddresses "127.0.0.1","77.88.8.8"

# --- 2. Установка ролей ---
Install-WindowsFeature -Name AD-Domain-Services, DHCP, DNS, FS-FileServer `
    -IncludeManagementTools

# --- 3. Создание домена hq.left ---
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName "hq.left" `
    -DomainNetbiosName "HQ" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force) `
    -InstallDns:$true `
    -Force:$true

# После перезагрузки выполни блок ниже (войти как administrator@hq.left)

# --- 4. DNS: форвардер и обратная зона ---
# (выполнять после перезагрузки и входа под доменным администратором)

Add-DnsServerForwarder -IPAddress "77.88.8.8"

# Обратная зона для 192.168.239.96/27
# Сеть /27: диапазон 192.168.239.96–127, обратная зона = 96-127.239.168.192.in-addr.arpa
Add-DnsServerPrimaryZone `
    -NetworkID "192.168.239.96/27" `
    -ReplicationScope "Domain"

# A и PTR записи
Add-DnsServerResourceRecordA -ZoneName "hq.left" -Name "fw-hq"  -IPv4Address "192.168.239.97"  -CreatePtr
Add-DnsServerResourceRecordA -ZoneName "hq.left" -Name "dca"    -IPv4Address "192.168.239.101" -CreatePtr
Add-DnsServerResourceRecordA -ZoneName "hq.left" -Name "web1"   -IPv4Address "192.168.239.105" -CreatePtr
Add-DnsServerResourceRecordA -ZoneName "hq.left" -Name "web2"   -IPv4Address "192.168.239.107" -CreatePtr

# CNAME записи
Add-DnsServerResourceRecordCName -ZoneName "hq.left" -Name "www"   -HostNameAlias "fw-hq.hq.left."
Add-DnsServerResourceRecordCName -ZoneName "hq.left" -Name "site1" -HostNameAlias "web1.hq.left."
Add-DnsServerResourceRecordCName -ZoneName "hq.left" -Name "site2" -HostNameAlias "web2.hq.left."

# --- 5. DHCP ---
# Область выдачи: 192.168.239.98 – 192.168.239.106 (7 адресов, ≥30% свободных)
# Зарезервированы: .97 (FW-HQ), .101 (DCA), .105 (WEB1), .107 (WEB2), .126 (DC-HQ)

Add-DhcpServerv4Scope `
    -Name "HQ_Local" `
    -StartRange "192.168.239.98" `
    -EndRange "192.168.239.106" `
    -SubnetMask "255.255.255.224" `
    -State Active

Set-DhcpServerv4OptionValue `
    -ScopeId "192.168.239.96" `
    -DnsServer "192.168.239.126" `
    -Router "192.168.239.97" `
    -DnsDomain "hq.left"

# Авторизуем DHCP в AD
Add-DhcpServerInDC -DnsName "dc-hq.hq.left" -IPAddress "192.168.239.126"

# Исключаем зарезервированные адреса из выдачи (на всякий случай)
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.239.96" `
    -StartRange "192.168.239.97" -EndRange "192.168.239.97"
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.239.96" `
    -StartRange "192.168.239.101" -EndRange "192.168.239.101"
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.239.96" `
    -StartRange "192.168.239.105" -EndRange "192.168.239.107"

Write-Host "=== DC-HQ настроен! ===" -ForegroundColor Green
