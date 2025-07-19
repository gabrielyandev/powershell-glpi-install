# GLPI Installer for Windows

[![Licença MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg?logo=powershell)](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-7.2)
[![GLPI Latest Release](https://img.shields.io/github/v/release/glpi-project/glpi?label=GLPI%20Latest)](https://github.com/glpi-project/glpi/releases/latest)

Um script PowerShell para automatizar a instalação inicial do GLPI (Gerenciador Livre de Projetos e Inventário) em ambientes Windows, ideal para servidores web como XAMPP ou WAMP.

---

## 📄 Sumário

- [Visão Geral](#-visão-geral)
- [Funcionalidades](#-funcionalidades)
- [Pré-requisitos](#-pré-requisitos)
- [Como Usar](#-como-usar)
  - [1. Configuração Inicial](#1-configuração-inicial)
  - [2. Executar o Script](#2-executar-o-script)
  - [3. Próximos Passos Pós-Instalação](#3-próximos-passos-pós-instalação)
    - [Permissões de Pasta](#permissões-de-pasta)
    - [Banco de Dados](#banco-de-dados)
    - [Configuração do PHP.INI](#configuração-do-phpini)
    - [Acesso à Instalação Web](#acesso-à-instalação-web)
- [Variáveis de Configuração](#-variáveis-de-configuração)
- [Troubleshooting](#-troubleshooting)
- [Contribuição](#-contribuição)
- [Licença](#-licença)
- [Autor](#-autor)

---

## 💡 Visão Geral

Este script PowerShell simplifica o processo de instalação do GLPI no Windows, baixando, extraindo e configurando os arquivos diretamente no diretório `htdocs` (ou similar) do seu servidor web local (XAMPP, WAMP, etc.). Ele foi projetado para automatizar as etapas tediosas e garantir que o ambiente base para o GLPI esteja pronto para a configuração final via navegador.

---

## ✨ Funcionalidades

* **Download Automatizado:** Baixa a versão especificada do GLPI diretamente do GitHub.
* **Extração Transparente:** Utiliza o `tar.exe` (nativo do Windows 10+) para extrair o pacote `.tgz`.
* **Movimentação de Arquivos:** Move os arquivos do GLPI para o diretório de destino configurado (ex: `C:\xampp\htdocs\glpi`).
* **Reinício de Serviços:** Tenta reiniciar os serviços Apache e MySQL/MariaDB para aplicar as mudanças.
* **Instruções Claras:** Fornece um guia passo a passo pós-instalação para configurar permissões, banco de dados e `php.ini`.

---

## 📋 Pré-requisitos

Antes de executar este script, certifique-se de que você tem:

* **PowerShell 5.1 ou superior:** Geralmente já vem com o Windows 10/11.
* **`tar.exe` disponível:** Nativo no Windows 10 Build 17063 e versões posteriores.
* **Conexão com a Internet:** Necessária para baixar o pacote do GLPI.
* **Servidor Web Funcional (XAMPP/WAMP/Apache/PHP/MySQL/MariaDB):** Uma instalação pré-existente e funcional é **obrigatória**. O script assume que você já tem um ambiente LAMP/WAMP configurado.
* **Permissões de Administrador:** O script **DEVE** ser executado como Administrador.

---

## 🚀 Como Usar

Siga os passos abaixo para instalar o GLPI usando este script.

### 1. Configuração Inicial

Abra o arquivo `install-glpi.ps1` em um editor de texto (como Notepad++, VS Code, etc.) e ajuste as seguintes variáveis de acordo com seu ambiente:

* `$glpiVersion`: A versão do GLPI que você deseja instalar. Verifique a [última versão estável](https://github.com/glpi-project/glpi/releases) no GitHub.
    ```powershell
    $glpiVersion = "10.0.19" # Exemplo: Verifique a última versão
    ```
* `$webRoot`: O caminho raiz do seu servidor web (ex: `C:\xampp\htdocs` para XAMPP, `C:\wamp64\www` para WAMP).
    ```powershell
    $webRoot = "C:\xampp\htdocs" # Ajuste para o seu diretório web
    ```
* `$apacheServiceName` e `$mysqlServiceName`: Os nomes dos serviços Apache e MySQL/MariaDB no Windows (você pode verificar em `services.msc`). O script tentará reiniciar esses serviços.
    ```powersershell
    $apacheServiceName = "Apache2.4" # Nome do serviço Apache
    $mysqlServiceName = "mysql"     # Nome do serviço MySQL/MariaDB
    ```

### 2. Executar o Script

1.  **Baixe o script:** Faça o download do arquivo `install-glpi.ps1` para uma pasta de sua preferência.
2.  **Abra o PowerShell como Administrador:**
    * Clique no Menu Iniciar, digite "PowerShell".
    * Clique com o botão direito em "Windows PowerShell" e selecione "Executar como administrador".
3.  **Navegue até o diretório do script:** Use o comando `cd` para ir até a pasta onde você salvou o script.
    ```powershell
    cd C:\caminho\para\o\seu\script
    ```
4.  **Execute o script:**
    ```powershell
    .\install-glpi.ps1
    ```
5.  O script exibirá o progresso no console. Acompanhe as mensagens e, se houver erros, eles serão detalhados.

### 3. Próximos Passos Pós-Instalação

Após a conclusão bem-sucedida do script, **É CRUCIAL** seguir estas etapas para finalizar a instalação do GLPI. O script fornecerá esses comandos no final, mas eles estão listados aqui para referência.

---

#### Permissões de Pasta

O GLPI precisa de permissões de escrita em algumas pastas para funcionar corretamente. O script instrui a configurar isso via Prompt de Comando:

1.  Abra o **Menu Iniciar**, digite `cmd`, clique com o botão direito em "Prompt de Comando" e selecione "Executar como administrador".
2.  Copie e cole os **TRÊS** comandos abaixo, um de cada vez, pressionando `Enter` após cada um:

    ```cmd
    icacls "C:\xampp\htdocs\glpi\files" /grant Usuarios:(OI)(CI)M /T
    icacls "C:\xampp\htdocs\glpi\config" /grant Usuarios:(OI)(CI)M /T
    icacls "C:\xampp\htdocs\glpi\plugins" /grant Usuarios:(OI)(CI)M /T
    ```
    *(Ajuste o caminho `C:\xampp\htdocs\glpi` se o seu `$webRoot` for diferente).*

---

#### Banco de Dados

Você precisa criar um banco de dados e um usuário para o GLPI no seu servidor MySQL/MariaDB (geralmente via phpMyAdmin).

1.  Acesse seu phpMyAdmin (normalmente `http://localhost/phpmyadmin`).
2.  Execute os seguintes comandos SQL na guia "SQL":

    ```sql
    CREATE DATABASE glpidb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER 'glpiuser'@'localhost' IDENTIFIED BY 'MasterKey!';
    GRANT ALL PRIVILEGES ON glpidb.* TO 'glpiuser'@'localhost';
    FLUSH PRIVILEGES;
    ```
    **IMPORTANTE:** **SUBSTITUA `'MasterKey!'` por uma senha segura e exclusiva!**

---

#### Configuração do PHP.INI

Para evitar problemas de tempo limite durante a instalação do GLPI, é recomendado aumentar o `max_execution_time`.

1.  Abra o painel de controle do seu servidor web (ex: XAMPP Control Panel).
2.  Ao lado de "Apache", clique no botão "Config" e selecione "PHP (php.ini)".
3.  No arquivo `php.ini` que se abrir, pressione `Ctrl+F` e procure por `max_execution_time`.
4.  Altere o valor para `300` (ex: `max_execution_time = 300`).
5.  Salve o arquivo e **REINICIE** o serviço do Apache no seu painel de controle (clique em "Stop" e depois em "Start").

---

#### Acesso à Instalação Web

Com todos os passos acima concluídos, você pode prosseguir com a instalação do GLPI via navegador:

* Abra seu navegador e acesse: `http://localhost/glpi`
* Siga as instruções na tela para completar a instalação do GLPI.

---

## ⚙️ Variáveis de Configuração

| Variável             | Descrição                                                                              | Valor Padrão (Exemplo) |
| :------------------- | :------------------------------------------------------------------------------------- | :--------------------- |
| `$glpiVersion`       | Versão do GLPI a ser baixada.                                                          | `"10.0.19"`            |
| `$glpiDownloadUrl`   | URL completa do pacote GLPI. Gerada automaticamente com base em `$glpiVersion`.        | *(Gerado)* |
| `$webRoot`           | Caminho absoluto para o diretório raiz do seu servidor web (ex: `htdocs` ou `www`).    | `"C:\xampp\htdocs"`    |
| `$glpiDestDir`       | Caminho completo para a pasta onde o GLPI será instalado. Gerado automaticamente.      | *(Gerado)* |
| `$apacheServiceName` | Nome do serviço Apache no Windows (verifique em `services.msc`).                       | `"Apache2.4"`          |
| `$mysqlServiceName`  | Nome do serviço MySQL/MariaDB no Windows (verifique em `services.msc`).                | `"mysql"`              |
| `$tempDir`           | Caminho para o diretório temporário usado durante o download e extração. Gerado.       | *(Gerado)* |

---

## 🚨 Troubleshooting

* **"ERRO CRITICO: O diretorio raiz '...' NAO foi encontrado."**: Verifique se a variável `$webRoot` está apontando para o caminho correto do seu diretório `htdocs` ou `www`.
* **"ERRO CRITICO: O comando 'tar.exe' nao foi encontrado."**: Certifique-se de que seu Windows é Build 17063+ (Windows 10, versão 1803 ou superior). Você pode verificar executando `winver` no Menu Iniciar.
* **"ERRO CRITICO no download..."**: Verifique sua conexão com a internet e se a `$glpiVersion` especificada realmente existe no [GitHub Releases do GLPI](https://github.com/glpi-project/glpi/releases).
* **"ERRO CRITICO ao copiar arquivos..." ou Problemas de Permissão**: Certifique-se de que você está executando o script PowerShell **como Administrador**. Sem isso, ele não terá as permissões necessárias para mover e criar pastas no diretório do servidor web.
* **Serviços Apache/MySQL não reiniciam**: Se você usa o XAMPP/WAMP Control Panel, é comum que os serviços não sejam gerenciados diretamente pelo `services.msc`. Neste caso, reinicie-os manualmente pelo painel de controle do XAMPP/WAMP. As mensagens de aviso no script são normais.

---

## 🤝 Contribuição

Contribuições são sempre bem-vindas! Se você tiver sugestões, melhorias ou encontrar bugs, sinta-se à vontade para abrir uma `issue` ou enviar um `pull request` no repositório.

---

## 📜 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## ✍️ Autor

**Gabriel Yan da Silva dos Santos** - [@gabrielyandev](https://github.com/gabrielyandev)

---