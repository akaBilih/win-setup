##########
# Win10 setup script
# Author: Ceynri <ceynri@gmail.com>
# Version: v1.0, 2021-06-06
# Source: https://github.com/ceynri/win10-setup
##########


##########
# Command list
##########

# import .psm1 module
Import-Module -Name "./setup.psm1" -ErrorAction Stop
Import-Module -Name "./tweaks.psm1" -ErrorAction Stop

# system settings
RequireAdmin


ResizeWindow

# install and show menu
Install-Module PSMenu
Clear-Host
ShowMenu