<#
.SYNOPSIS
    Script PowerShell para instalar o GLPI no Windows.

.DESCRIPTION
    Este script automatiza as seguintes etapas:
    - Define variaveis para a versao do GLPI, URLs e caminhos de instalacao.
    - Configura o protocolo de seguranca TLS para downloads HTTPS.
    - Baixa o pacote de instalacao do GLPI (suporta .tgz).
    - Extrai o conteudo do pacote GLPI usando 'tar.exe'.
    - Move os arquivos do GLPI para o diretorio htdocs do Apache (XAMPP/WAMP).
    - Tenta reiniciar os servicos Apache e MySQL/MariaDB (avisa se nao encontrar).

.NOTES
    Autor: Gabriel Yan da Silva dos Santos (@gabrielyandev)
    Versao: 1.0.0
    Local: Salvador, Bahia, Brasil (informacao do contexto)

.PREREQUISITES
    - PowerShell 5.1 ou superior (ja vem com Windows 10/11).
    - Comando 'tar.exe' disponivel (nativo no Windows 10 build 17063+).
    - Conexao com a internet para baixar o GLPI.
    - XAMPP, WAMP ou instalacao Apache/PHP/MySQL/MariaDB pre-existente e funcional.
    - EXECUTAR O SCRIPT COMO ADMINISTRADOR E OBRIGATORIO.
#>

# --- Configuracoes Essenciais do Script ---
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " INICIANDO INSTALACAO AUTOMATIZADA DO GLPI NO WINDOWS " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Data/Hora Local: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Gray
Write-Host "Localidade: Salvador, Bahia, Brasil" -ForegroundColor Gray
Write-Host "Desenvolvedor: Gabriel Yan da Silva dos Santos - @gabrielyandev << https://github.com/gabrielyandev >>" -ForegroundColor Gray
Write-Host ""

# --- 1. Definir Variaveis de Configuracao (AJUSTE AQUI!) ---
Write-Host "1. Definindo variaveis de configuracao..." -ForegroundColor Yellow

# VERSAO DO GLPI:
$glpiVersion = "10.0.19" # Verifique a ultima versao estavel em https://github.com/glpi-project/glpi/releases

# URL DE DOWNLOAD DO GLPI:
$glpiDownloadUrl = "https://github.com/glpi-project/glpi/releases/download/$glpiVersion/glpi-$glpiVersion.tgz"

# CAMINHO RAIZ DO SEU SERVIDOR WEB (Ex: C:\xampp\htdocs, C:\wamp64\www)
$webRoot = "C:\xampp\htdocs"

# DIRETORIO DE INSTALACAO FINAL DO GLPI:
$glpiDestDir = Join-Path $webRoot "glpi"

# NOMES DOS SERVICOS (verifique em services.msc):
$apacheServiceName = "Apache2.4"
$mysqlServiceName = "mysql"

# CAMINHO TEMPORARIO (automatico):
$tempDir = Join-Path $env:TEMP "glpi_install_$((Get-Random).ToString().Substring(0,4))"

Write-Host "   - Versao GLPI: $glpiVersion" -ForegroundColor DarkGray
Write-Host "   - Diretorio Web: $webRoot" -ForegroundColor DarkGray
Write-Host ""

# --- 2. Pre-verificacoes Essenciais ---
Write-Host "2. Realizando pre-verificacoes do ambiente..." -ForegroundColor Yellow

if (-not (Test-Path $webRoot)) {
    Write-Error "ERRO CRITICO: O diretorio raiz '$webRoot' NAO foi encontrado. Ajuste a variavel `$webRoot no script."
    Read-Host "Pressione Enter para sair."
    exit 1
}
if (-not (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
    Write-Error "ERRO CRITICO: O comando 'tar.exe' nao foi encontrado. E nativo no Windows 10 (Build 17063+) e superior."
    Read-Host "Pressione Enter para sair."
    exit 1
}
if (-not (Get-Service -Name $apacheServiceName -ErrorAction SilentlyContinue)) {
    Write-Warning "AVISO: Servico Apache '$apacheServiceName' nao encontrado. Normal se voce usa o XAMPP Control Panel."
}
if (-not (Get-Service -Name $mysqlServiceName -ErrorAction SilentlyContinue)) {
    Write-Warning "AVISO: Servico MySQL/MariaDB '$mysqlServiceName' nao encontrado. Normal se voce usa o XAMPP Control Panel."
}
Write-Host ""

# --- 3. Configurar Protocolo de Seguranca ---
Write-Host "3. Configurando protocolo de seguranca TLS 1.2..." -ForegroundColor Cyan
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls
Write-Host "   Protocolo configurado." -ForegroundColor Green
Write-Host ""

# --- 4. Baixar e Extrair o GLPI ---
Write-Host "4. Baixando e extraindo o GLPI..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$glpiTgzPath = Join-Path $tempDir "glpi-$glpiVersion.tgz"

Write-Host "   Baixando de: $glpiDownloadUrl" -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $glpiDownloadUrl -OutFile $glpiTgzPath -UseBasicParsing
    Write-Host "   Download concluido." -ForegroundColor Green
}
catch {
    Write-Error "ERRO CRITICO no download: $($_.Exception.Message). Verifique a URL e sua conexao."
    Read-Host "Pressione Enter para sair."
    exit 1
}

Write-Host "   Extraindo arquivos..." -ForegroundColor Cyan
try {
    & tar.exe -xf $glpiTgzPath -C $tempDir
    Write-Host "   Extracao concluida." -ForegroundColor Green
}
catch {
    Write-Error "ERRO CRITICO ao extrair: $($_.Exception.Message). O arquivo pode estar corrompido."
    Read-Host "Pressione Enter para sair."
    exit 1
}
Write-Host ""

$glpiSourceDir = Get-ChildItem -Path $tempDir | Where-Object {$_.PSIsContainer -and $_.Name -like "glpi*"} | Select-Object -First 1 -ExpandProperty FullName
if (-not $glpiSourceDir) {
    Write-Error "ERRO CRITICO: Nao foi possivel encontrar a pasta de origem do GLPI apos a extracao."
    Read-Host "Pressione Enter para sair."
    exit 1
}

# --- 5. Mover para o Diretorio Web ---
Write-Host "5. Movendo arquivos para o diretorio web..." -ForegroundColor Yellow

if (Test-Path $glpiDestDir) {
    Write-Host "   Removendo instalacao antiga em '$glpiDestDir'..." -ForegroundColor Cyan
    Remove-Item -Path $glpiDestDir -Recurse -Force
}

Write-Host "   Criando diretorio de destino '$glpiDestDir'..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $glpiDestDir -Force | Out-Null

Write-Host "   Copiando arquivos para '$glpiDestDir'..." -ForegroundColor Cyan
try {
    Copy-Item -Path "$glpiSourceDir\*" -Destination $glpiDestDir -Recurse -Force
    Write-Host "   Copia concluida." -ForegroundColor Green
}
catch {
    Write-Error "ERRO CRITICO ao copiar arquivos: $($_.Exception.Message)"
    Write-Error "Verifique as permissoes e se o script esta rodando como Administrador."
    Read-Host "Pressione Enter para sair."
    exit 1
}
Write-Host ""

# --- 6. Configurar Permissoes de Pasta (DESATIVADO) ---
# Write-Host "6. Configurando permissoes de pasta... (ETAPA DESATIVADA)" -ForegroundColor Yellow
# Write-Host "   As permissoes deverao ser configuradas manualmente conforme instrucoes no final." -ForegroundColor Yellow
#
# $foldersToSetWritePermissions = @(
#     "files",
#     "files\_cache",
#     "files\_log",
#     "files\_dumps",
#     "files\_pictures",
#     "config",
#     "plugins"
# )
#
# foreach ($folderName in $foldersToSetWritePermissions) {
#     $folderPath = Join-Path $glpiDestDir $folderName
#     if (Test-Path $folderPath) {
#         Write-Host "   - (PULADO) Definindo permissoes para: $folderPath"
#     }
# }
Write-Host ""

# --- 7. Reiniciar Servicos ---
Write-Host "7. Tentando reiniciar servicos..." -ForegroundColor Yellow
# Apache
if (Get-Service -Name $apacheServiceName -ErrorAction SilentlyContinue) {
    try {
        Restart-Service -Name $apacheServiceName -Force
        Write-Host "   Servico '$apacheServiceName' reiniciado." -ForegroundColor Green
    } catch { Write-Warning "AVISO: Nao foi possivel reiniciar o Apache. Reinicie manualmente." }
} else { Write-Warning "AVISO: Servico Apache nao encontrado para reinicio automatico." }
# MySQL/MariaDB
if (Get-Service -Name $mysqlServiceName -ErrorAction SilentlyContinue) {
    try {
        Restart-Service -Name $mysqlServiceName -Force
        Write-Host "   Servico '$mysqlServiceName' reiniciado." -ForegroundColor Green
    } catch { Write-Warning "AVISO: Nao foi possivel reiniciar o MySQL/MariaDB. Reinicie manualmente." }
} else { Write-Warning "AVISO: Servico MySQL/MariaDB nao encontrado para reinicio automatico." }
Write-Host ""

# --- 8. Limpeza Final ---
Write-Host "8. Limpando arquivos temporarios..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   Limpeza concluida." -ForegroundColor Green
Write-Host ""

# --- 9. Proximos Passos ---
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " INSTALACAO DA BASE DO GLPI CONCLUIDA." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "--- PROXIMOS PASSOS CRUCIAIS: ---" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. CONFIGURAR PERMISSOES (NOVO METODO - PROMPT DE COMANDO):" -ForegroundColor Red
Write-Host "   - Abra o Menu Iniciar, digite 'cmd', clique com o botao direito em 'Prompt de Comando' e selecione 'Executar como administrador'." -ForegroundColor White
Write-Host "   - Na tela preta que abrir, copie e cole os TRES comandos abaixo, um de cada vez, pressionando Enter apos cada um:" -ForegroundColor White
Write-Host '   icacls "C:\xampp\htdocs\glpi\files" /grant Usuarios:(OI)(CI)M /T' -ForegroundColor DarkCyan
Write-Host '   icacls "C:\xampp\htdocs\glpi\config" /grant Usuarios:(OI)(CI)M /T' -ForegroundColor DarkCyan
Write-Host '   icacls "C:\xampp\htdocs\glpi\plugins" /grant Usuarios:(OI)(CI)M /T' -ForegroundColor DarkCyan
Write-Host ""
Write-Host "2. BANCO DE DADOS: Crie o banco de dados e o usuario no phpMyAdmin." -ForegroundColor White
Write-Host "   Execute os seguintes comandos SQL:" -ForegroundColor White

$sqlExample = @"
    CREATE DATABASE glpidb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER 'glpiuser'@'localhost' IDENTIFIED BY 'MasterKey!';
    GRANT ALL PRIVILEGES ON glpidb.* TO 'glpiuser'@'localhost';
    FLUSH PRIVILEGES;
"@
Write-Host $sqlExample -ForegroundColor DarkCyan
Write-Host "   **SUBSTITUA 'MasterKey!' por uma senha segura!**" -ForegroundColor Red
Write-Host ""
Write-Host "3. PHP.INI (PASSO OBRIGATORIO PARA CORRIGIR O ERRO DE TEMPO):" -ForegroundColor Red
Write-Host "   - Abra o XAMPP Control Panel e clique no botao 'Config' ao lado de 'Apache', depois selecione 'PHP (php.ini)'." -ForegroundColor White
Write-Host "   - No arquivo que abrir, pressione Ctrl+F e procure por 'max_execution_time'." -ForegroundColor White
Write-Host "   - Altere o valor para 300 (ex: max_execution_time = 300)." -ForegroundColor White
Write-Host "   - Salve o arquivo e REINICIE o servico do Apache no XAMPP Control Panel (clique em 'Stop' e depois em 'Start')." -ForegroundColor White
Write-Host ""
Write-Host "4. FINALIZAR: Abra seu navegador e acesse http://localhost/glpi para iniciar a instalacao do zero." -ForegroundColor White
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " PROCESSO CONCLUIDO. " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Pressione Enter para fechar esta janela." | Out-Null

# --- FIM DO SCRIPT ---
