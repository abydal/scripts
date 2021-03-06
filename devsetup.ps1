# Install or upgrade chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install powershell-core --version=7.1.4 -y
choco install microsoft windows-terminal -y
choco install dotnet-5.0-sdk -y
choco install git /WindowsTerminal -y
choco install vscode -y
choco install wsl2 -y
choco install azure-cli -y
choco install terraform -y
choco install docker-desktop -y
choco install sql-server-management-studio -y

# Add "open windows terminal here" context menu item
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/lextm/windowsterminal-shell/master/install.ps1'))
