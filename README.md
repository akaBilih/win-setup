# Windows 10 Setup Scripts

Windows 10 setup scripts for fresh installs. By executing the script, you can complete your scheduled system configuration and the installation of common software **semi-automatically**.

## Run with
```
irm https://utils.bielgonzalez.es/win-setup | iex
```

## What will the scripts do

> The following is my personal configuration, you can modify the script to suit your usage habits.

### Modify system config

- Activate win10 by [kmspro](https://github.com/dylanbai8/kmspro)
- Set a new computer name
- Set power settings
- Excute Tweaks from [Disassembler0/Win10-Initial-Setup-Script](https://github.com/Disassembler0/Win10-Initial-Setup-Script)
  - Disable Cortana, AdvertisingID, UpdateRestart...
  - Set DeveloperMode, DarkMode, SmallTaskbarIcons...
  - Hide LibraryMenu, RecentShortcuts...
  - Uninstall OneDrive, Xbox...

### Install Applications

- Remove built-in apps
  - Skype
  - YourPhone
  - Print3D
  - GetHelp
  - ...
- Install apps by Winget
  - Git, NodeJS, Miniconda
  - ...
- Install apps by Chocolaty (that can't be installed from Winget)
  - v2ray
  - ffmpeg
  - traffic-monitor
  - ...
- Show other app tips that have not been downloaded (add -url can be downloaded via wget)
  - Snipaste
  - WGestures
  - ...

### Others

- Configure the environment
  - Set git name and email
  - Enable git proxy
  - Enable npm taobao registry
- Restart computer

## Prerequisites

- A fresh install of Windows 10.

## Usage

Fork or download this repo, **MODIFY** the scripts, and execute `setup.cmd` in your fresh installed computer.

**Run it as Administrator** to ensure that the script can run normally.

> The script has not been fully tested after each modification, please be careful if you are using it.
>
> You’d better understand what the scripts do if you run them. Some functions lower security, hide controls or uninstall applications. You'll most likely need to modify the scripts.

## Structure

### setup.cmd

Execute `setup.ps1` bypassing the default setting that does not allow `.ps1` scripts to be executed in Win10.

### setup.ps1

Contains the main flow of the script, which calls functions in `setup.psm1`

### setup.psm1

Some wrapped atomic operations are called by setup.ps1

### tweaks.\*

A transplant from [Disassembler0/Win10-Initial-Setup-Script](https://github.com/Disassembler0/Win10-Initial-Setup-Script).

`tweaks.preset` is my custom preset. You'd better write a preset yourself compared with the original project.

### optional

Some scripts or registries that you can selectively execute. Please check the README in the folder for details.

## Thanks

- [Disassembler0/Win10-Initial-Setup-Script](https://github.com/Disassembler0/Win10-Initial-Setup-Script)
- [EdiWang/EnvSetup](https://github.com/EdiWang/EnvSetup)
- [dylanbai8/kmspro](https://github.com/dylanbai8/kmspro)
- [winget](https://github.com/microsoft/winget-cli)
- [choco](https://github.com/chocolatey/choco)

## License

MIT © ceynri
