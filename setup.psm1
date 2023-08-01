##########
# Win10 setup - Tweak library
# Author: Ceynri <ceynri@gmail.com>
# Version: v1.0, 2021-06-06
# Source: https://github.com/ceynri/win10-setup
# Extended from: https://github.com/Disassembler0/Win10-Initial-Setup-Script
##########

# generate a temporary directory name (without creating it)
Function GenerateTmpDir {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    Join-Path $parent $name
}

##########
# global variable
##########
$configFile = "config.json"
$global:Config = Get-Content "$configFile" -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue | ConvertFrom-Json -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue

$userDir = $env:USERPROFILE
$workspaceDir = "$userDir\workspace"

##########
# App list
##########

# add -url can download by wget
# Do not add extra spaces to separate app name
$notInstalledApps = @(
    #"Snipaste.zip -url https://dl.snipaste.com/win-x64-beta-cn",
    #"WGestures.zip -url https://www.yingdev.com/Content/Projects/WGestures/Release/1.8.4.0/Install%20WGestures%201.8.4.0.zip",

    #"Office365",
    #"OfficeToolPlus",
    #"PhotoShop",
    #"Premiere",

    #"WSL",

    #"BaiduNetDisk: https://pan.baidu.com/download"
)

##########
# menu
##########
class MyMenuOption {
    [String]$DisplayName
    [ScriptBlock]$Script

    [String]ToString() {
        Return $This.DisplayName
    }
}

function New-MenuItem([String]$DisplayName, [ScriptBlock]$Script) {
    $MenuItem = [MyMenuOption]::new()
    $MenuItem.DisplayName = $DisplayName
    $MenuItem.Script = [ScriptBlock]::Create("Clear-Host" + "`n" + $Script)
    Return $MenuItem
}

$global:Menus = @{
    Main  = @(
        $(New-MenuItem -DisplayName "Run all steps from start to finish" -Script { RunAll }),
        $(New-MenuItem -DisplayName "Run from selected step to end" -Script { RunFrom }),
        $(New-MenuItem -DisplayName "Run from and to selected steps" -Script { RunFromTo }),
        $(New-MenuItem -DisplayName "Run the selected step" -Script { RunOnly }),
        $(Get-MenuSeparator),
        $(New-MenuItem -DisplayName "Show other tools" -Script { ShowMenu($global:Menus.Tools) }),
        $(Get-MenuSeparator),
        $(New-MenuItem -DisplayName "Display all steps in order" -Script { DisplaySteps }),
        $(Get-MenuSeparator),
        $(New-MenuItem -DisplayName "Quit" -Script { exit })
    );

    Tools = @(
        $(New-MenuItem -DisplayName "Install Winget package" -Script { ToolInstallWinget }),
        $(New-MenuItem -DisplayName "Install Chocolatey package" -Script { ToolInstallChoco }),
        $(Get-MenuSeparator),
        $(New-MenuItem -DisplayName "Return" -Script { ShowMenu($global:Menus.Main) })
    )
}
function ShowMenu($opts) {
    
    Write-Host
    Write-Host

    Write-Host "    (¯``-.-´¯``-.¸¸.-´¯``-.¸¸.-´¯``-.¸¸.-´¯``-.¸¸.-´¯``-.-´¯)"
    Write-Host "     (                                               ) "
    Write-Host "      (    Welcome to akaBilih's win-setup script   )  "
    Write-Host "       (                                           )   "
    Write-Host "        (-´¯``-.¸¸.-´¯``-.¸¸.-´¯``-.¸¸.-´¯``-.¸¸.-´¯``-)"

    Write-Host
    Write-Host
    Write-Host
    Write-Host
    
    $Chosen = Show-Menu -MenuItems $opts
    if ($Chosen) {
        & $Chosen.Script
    }
    else {
        exit
    }
    ShowMenu($global:Menus.Main)
}

$global:Steps = @(  
    "ActivateWin10", 
    "RenameComputerName",
    "setPowerSettings",
    "executeTweaks",
    # application management
    "UninstallMsftBloat",
    # install by winget
    "InstallWinget",
    "InstallAppByWinget",
    "RefreshEnv",
    # install by choco
    "InstallChoco ",
    "InstallAppByChoco",
    "RefreshEnv ",
    # others
    "ManualInstallApp",
    # environment settings
    "SetGitNameAndEmail",
    "CreateWorkspaceDir",
    "CloneGitRepos",
    # end
    "RemoveTmpCheck",
    "RestartTips"
)
function DisplaySteps($steps = $global:Steps) {
    for ($i = 0; $i -lt $steps.Count; $i++) {
        Write-Host (([string]($i + 1)) + ") " + $steps[$i])
    }
    Write-Host
    Pause
    Clear-Host
}

function ExecuteSteps($steps) {
    Write-Host "This will execute the following steps:"
    DisplaySteps($steps)
    
    foreach ($cmd in $steps) {
        Write-Host "The next step is `"$cmd`". Delaying start 5 seconds..." 
        Start-Sleep 5
        Write-Host "Executing step `"$cmd`""
        Invoke-Expression $cmd
        Write-Host "Finished executing step `"$cmd`""
    }

    Write-Host "Steps executed correctly"
    Write-Host 
    Pause
    Clear-Host
}
function SelectStep($startIndex = 0) {
    $steps = $global:Steps[$startIndex..($global:Steps.Count - 1)]
    $result = Show-Menu -MenuItems $steps -ReturnIndex
    Clear-Host
    return $result 
}

function RunAll() {
    ExecuteSteps($global:Steps)
}

function RunFrom() {
    $step = SelectStep
    $steps = $global:Steps[$step..($global:Steps.Count - 1)]

    ExecuteSteps($steps)
}
function RunFromTo() {
    $step1 = SelectStep
    $step2 = SelectStep($step1)
    
    $steps = $global:Steps[$step1..($step1 + $step2)]

    ExecuteSteps($steps)
}

function RunOnly() {
    $step = SelectStep
    $steps = $global:Steps[$step]

    ExecuteSteps($steps)
}


##########
# tools
##########
Function PromptReinstall() {
    $question = "The package is already installed. Are you sure you want to reinstall?"
    $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

    $decision = $Host.UI.PromptForChoice("", $question, $choices, 1)
    if ($decision -eq 0) {
        return $true
    }
    else {
        return $false
    }
}

Function ToolInstallWinget() {
    $package = Read-Host -Prompt "Input the package name" 
    powershell "winget install $package -e"
    Pause
    ShowMenu($global:Menus.Tools)
}
Function ToolInstallChoco() {
    $package = Read-Host -Prompt "Input the package name" 
    $installed = choco list
    $isInstalled = $installed -Match $package
    if ($isInstalled) {
        if (PromptReinstall) {
            choco install $package -y -f
        }
    }else{
        choco install $package -y
    }
    Pause
    ShowMenu($global:Menus.Tools)
}

##########
# utils
##########

# Relaunch the script with administrator privileges
Function RequireAdmin {
    if (!
        #current role
        (New-Object Security.Principal.WindowsPrincipal(
            [Security.Principal.WindowsIdentity]::GetCurrent()
            #is admin?
        )).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    ) {
        #elevate script and exit current non-elevated runtime
        $adminprcs = Start-Process -FilePath 'powershell' -ArgumentList ('-Command', 'cd' , $MyInvocation.PSScriptRoot, ";", $MyInvocation.PSCommandPath, $args | % { $_ }) -Verb RunAs -PassThru 
        $adminprcs.WaitForExit()
        exit
    }
}

# check command is exist
Function CheckCommand($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# create a temp directory
Function CreateTmpDir() {
    PrintLog "Creating the temp directory..."
    $global:tmpDir = (GenerateTmpDir).FullName
    New-Item -ItemType Directory -Path $global:tmpDir
}

# remove the temp directory
Function RemoveTmpDir() {
    PrintLog "Removing the temp directory..."
    Remove-Item $global:tmpDir -recurse -ErrorAction SilentlyContinue
}

# create a temp directory
Function CreateWorkspaceDir() {
    PrintLog "Checking the workspace directory..."
    New-Item -Path $userDir -Name "workspace" -type directory -ErrorAction SilentlyContinue
}

Function RefreshEnv() {
    $expanded = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    $previous = ''
    while ($previous -ne $expanded) {
        $previous = $expanded
        $expanded = [System.Environment]::ExpandEnvironmentVariables($previous)
    }
    $env:Path = $expanded
}

##########
# win10 settings
##########

# Activate win10 by [kmspro](https://github.com/dylanbai8/kmspro)
Function ActivateWin10() {
    PrintLog "Activating win10 by kmspro..."
    slmgr /skms kms.v0v.bid; slmgr /ato
}

# rename computer name
Function RenameComputerName() {
    $computerName = Read-Host 'Enter New Computer Name'
    PrintWarn "Renaming this computer to: " $computerName
    Rename-Computer -NewName $computerName
}

# change sleep settings
# If your laptop is often unable to wake up from sleep, set it to 0 and shutdown manually when needed
Function setPowerSettings() {
    PrintLog "Setting display and sleep mode timeouts..."
    powercfg /X monitor-timeout-ac 10
    powercfg /X monitor-timeout-dc 5
    powercfg /X standby-timeout-ac 0
    powercfg /X standby-timeout-dc 45
}

Function executeTweaks() {
    $tweaks = ($global:Config.tweaks | ForEach-Object { $_ | Get-Member -MemberType NoteProperty } | Select-Object -Unique -ExpandProperty Name) | ForEach-Object { $x = $_; return (($global:Config.tweaks | Select-Object -Unique -ExpandProperty "$_") | ForEach-Object { $x + $_ }) }
    foreach ($tweak in $tweaks) {
        $tweak | ForEach-Object { Invoke-Expression $_ }
    }
}

##########
# remove pre-installed Apps
##########

# To list all appx packages: (You can find out which apps you don’t need)
Function ListAllAppxPkgs() {
    Get-AppxPackage | Format-Table -Property Name, Version, PackageFullName
}

# remove UWP rubbish
Function UninstallMsftBloat() {
    PrintLog "Uninstalling default Microsoft applications..."
    foreach ($app in $global:Config.apps.remove.msbloat) {
        Get-AppxPackage $app | Remove-AppxPackage
    }
}

##########
# install Apps
##########

Function ProxyWarning() {
    PrintWarn "[WARN] If you are in China: please make sure the system proxy is turned on to access the true internet firstly!"
    WaitForKey
}

Function ChocoProxyWarning() {
    PrintWarn "[WARN] Choco will be installed next, enable global proxy is more secure if you are in china"
    WaitForKey
}

# Download installation package by wget
Function WgetDownloadAndInstall($name, $url, $dir) {
    PrintLog "Downloading $name installation package..."
    PrintLog "Please execute install manually in the open window when download is complete"
    $path = "$dir\$name"
    wget -O $path $url
    &$path
    PrintWarn "Enter any key until the installation is complete"
    WaitForKey
}

# install winget
Function InstallWinget() {
    if (CheckCommand -cmdname 'winget') {
        PrintLog "Winget is already installed, skip installation."
    }
    else {
        $name = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
        $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
        WgetDownloadAndInstall -name $name -url $url -dir $global:tmpDir
        Remove-Item $global:tmpDir\$name
    }
}

# install choco
Function InstallChoco() {
    if (CheckCommand -cmdname 'choco') {
        PrintLog "Choco is already installed, skip installation."
    }
    else {
        PrintLog "Installing Chocolate..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

# install essential apps by winget
Function InstallAppByWinget() {
    if (CheckCommand -cmdname 'winget') {
        PrintLog "Installing Essential Applications by winget..."
        foreach ($app in $global:Config.apps.add.winget) {
            # use string as a command for carrying args in the $app
            powershell "winget install $app -e"
        }
    }
    else {
        PrintError "Can not find 'winget' command, skip the installation."
    }
}

# install essential apps by choco
Function InstallAppByChoco() {
    if (CheckCommand -cmdname 'choco') {
        PrintLog "Installing Essential Applications by choco..."
        foreach ($app in $global:Config.apps.add.chocolatey) {
            choco install $app -y
        }
    }
    else {
        PrintError "Can not find 'choco' command, skip the installation."
    }
}

# install npm global packages
# Function InstallNpmPackage($npmPackages) {
#     if (CheckCommand -cmdname 'npm') {
#         PrintLog "Installing npm global node packages..."
#         foreach ($package in $npmPackages) {
#             npm install -g $package
#         }
#     }
#     else {
#         PrintError "Can not find 'npm' command, skip the installation."
#     }
# }

# install apps manually
Function ManualInstallApp() {
    PrintLog "There are also the following uninstalled apps, you need to install manually:"
    foreach ($app in $notInstalledApps) {
        $splitNameAndUrl = $app.split(" ");
        if ($splitNameAndUrl.Length -eq 3) {
            PrintInfo "$app (download link exists)"
            $name = $splitNameAndUrl[0]
            $url = $splitNameAndUrl[2]
            WgetDownloadAndInstall -name $name -url $url -dir $global:tmpDir
        }
        else {
            PrintInfo "$app"
        }
    }
}

# clone essential git repository
Function CloneGitRepos() {
    if (CheckCommand -cmdname 'git') {
        PrintLog "Cloning essential git repositorys..."
        foreach ($repo in $global:Config.git.repos) {
            git clone "https://github.com/ceynri/$repo.git" "$workspaceDir/$repo"
        }
    }
    else {
        PrintError "Can not find 'git' command, skip the clone."
    }
}

##########
# Env settings
##########

Function EnableGlobalProxy($port) {
    $env:HTTP_PROXY = "http://127.0.0.1:$port"
    $env:HTTPS_PROXY = "http://127.0.0.1:$port"
}

Function DisableGlobalProxy() {
    $env:HTTP_PROXY = ""
    $env:HTTPS_PROXY = ""
}

Function SetGitNameAndEmail() {
    if (CheckCommand -cmdname 'git') {
        git config --global user.name $global:Config.git.config.user
        git config --global user.email $global:Config.git.config.email
    }
    else {
        PrintError "Can not find 'git' command, skip set git name and email."
    }
}

Function EnableGitProxy($port) {
    if (CheckCommand -cmdname 'git') {
        git config --global http.proxy "http://127.0.0.1:$port"
        git config --global https.proxy "http://127.0.0.1:$port"
    }
    else {
        PrintError "Can not find 'git' command, skip enable git proxy."
    }
}

Function DisableGitProxy($port) {
    if (CheckCommand -cmdname 'git') {
        git config --global --unset http.proxy
        git config --global --unset https.proxy
    }
    else {
        PrintError "Can not find 'git' command, skip disable git proxy."
    }
}

Function SetGitSchannel() {
    if (CheckCommand -cmdname 'git') {
        git config --global http.sslBackend schannel
    }
    else {
        PrintError "Can not find 'git' command, skip set git schannel."
    }
}

Function EnableNpmRegistry() {
    if (CheckCommand -cmdname 'npm') {
        npm config set registry "https://registry.npm.taobao.org"
    }
    else {
        PrintError "Can not find 'npm' command, skip enable npm registry."
    }
}

Function EnableNpmProxy($port) {
    if (CheckCommand -cmdname 'npm') {
        npm config set proxy "http://127.0.0.1:$port"
        npm config set https-proxy "http://127.0.0.1:$port"
    }
    else {
        PrintError "Can not find 'npm' command, skip enable npm proxy."
    }
}

Function AddNvmMirror() {
    NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node
}

Function AddNodeSassMirror() {
    SASS_BINARY_SITE=http://npm.taobao.org/mirrors/node-sass
}

Function InstallWindowsBuildTools() {
    set "PYTHON_MIRROR=http://npm.taobao.org/mirrors/python"
    if (CheckCommand -cmdname 'npm') {
        # If the output hang on the "Successfully installed Python 2.7", you may need to solve it yourself.
        # Related issue: https://github.com/felixrieseberg/windows-build-tools/issues/172
        # For me: npm install --global --production windows-build-tools@4.0.0
        npm install --global --production windows-build-tools
    }
    else {
        PrintError "Can not find 'npm' command, skip install windows-build-tools."
    }
}

##########
# Auxiliary Functions
##########

Function WaitForKey() {
    Write-Output "`nPress any key to continue..."
    [Console]::ReadKey($true) | Out-Null
}

Function PrintInfo($str) {
    Write-Host $str -ForegroundColor Gray
}

Function PrintLog($str) {
    Write-Host $str -ForegroundColor Green
}

Function PrintWarn($str) {
    Write-Host $str -ForegroundColor Yellow
}

Function PrintError($str) {
    Write-Host $str -ForegroundColor Red
}

Function RemoveTmpCheck() {
    $removeInput = Read-Host "Remove the 'tmp' directory (if you had install all installation package in 'tmp' dircetory) (y/[N])"
    if ((('y', 'Y', 'yes') -contains $removeInput)) {
        RemoveTmpDir
    }
}

Function RestartTips() {
    $restartInput = Read-Host "Setup is done, restart is needed, input 'y' to restart computer. (y/[N])"
    if ((('y', 'Y', 'yes') -contains $restartInput)) {
        Restart-Computer
    }
    else {
        RefreshEnv
    }
}

Function Set-Window {
    <#
        .SYNOPSIS
            Sets the window size (height,width) and coordinates (x,y) of
            a process window.
        .DESCRIPTION
            Sets the window size (height,width) and coordinates (x,y) of
            a process window.

        .PARAMETER ProcessId
            Name of the process to determine the window characteristics

        .PARAMETER X
            Set the position of the window in pixels from the top.

        .PARAMETER Y
            Set the position of the window in pixels from the left.

        .PARAMETER Width
            Set the width of the window.

        .PARAMETER Height
            Set the height of the window.

        .PARAMETER Passthru
            Display the output object of the window.

        .NOTES
            Name: Set-Window
            Author: Boe Prox
            Version History
                1.0//Boe Prox - 11/24/2015
                    - Initial build

        .OUTPUT
            System.Automation.WindowInfo

        .EXAMPLE
            Get-Process powershell | Set-Window -X 2040 -Y 142 -Passthru

            ProcessId$ProcessId Size     TopLeft  BottomRight
            ----------- ----     -------  -----------
            powershell  1262,642 2040,142 3302,784   

            Description
            -----------
            Set the coordinates on the window for the process PowerShell.exe

    #>
    [OutputType('System.Automation.WindowInfo')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipelineByPropertyName = $True)]
        $ProcessId,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [switch]$Passthru
    )
    Begin {
        Try {
            [void][Window]
        }
        Catch {
            Add-Type @"
              using System;
              using System.Runtime.InteropServices;
              public class Window {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

                [DllImport("User32.dll")]
                public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
              }
              public struct RECT
              {
                public int Left;        // x position of upper-left corner
                public int Top;         // y position of upper-left corner
                public int Right;       // x position of lower-right corner
                public int Bottom;      // y position of lower-right corner
              }
"@
        }
    }
    Process {
        $Rectangle = New-Object RECT
        $Handle = (Get-Process -id $ProcessId).MainWindowHandle
        $Return = [Window]::GetWindowRect($Handle, [ref]$Rectangle)
        If (-NOT $PSBoundParameters.ContainsKey('Width')) {            
            $Width = $Rectangle.Right - $Rectangle.Left            
        }
        If (-NOT $PSBoundParameters.ContainsKey('Height')) {
            $Height = $Rectangle.Bottom - $Rectangle.Top
        }
        If ($Return) {
            $Return = [Window]::MoveWindow($Handle, $x, $y, $Width, $Height, $True)
        }
        If ($PSBoundParameters.ContainsKey('Passthru')) {
            $Rectangle = New-Object RECT
            $Return = [Window]::GetWindowRect($Handle, [ref]$Rectangle)
            If ($Return) {
                $Height = $Rectangle.Bottom - $Rectangle.Top
                $Width = $Rectangle.Right - $Rectangle.Left
                $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
                $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
                $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
                If ($Rectangle.Top -lt 0 -AND $Rectangle.LEft -lt 0) {
                    Write-Warning "Window is minimized! Coordinates will not be accurate."
                }
                $Object = [pscustomobject]@{
                    $ProcessId  = $ProcessId
                    Size        = $Size
                    TopLeft     = $TopLeft
                    BottomRight = $BottomRight
                }
                $Object.PSTypeNames.insert(0, 'System.Automation.WindowInfo')
                $Object            
            }
        }
    }
}


function ResizeWindow() {
    $monitor = Get-WmiObject -Class Win32_DesktopMonitor
    [double]$sw = $monitor.ScreenWidth
    [double]$sh = $monitor.ScreenHeight
    
    $w = 650
    $h = 500
    
    $x = ($sw / 2) - ($w / 2)
    $y = ($sh / 2) - ($h / 2)
    Set-Window -ProcessId $pid -X $x -Y $y -Width $w -Height $h
}

Export-ModuleMember -Function *
