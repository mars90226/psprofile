function which($cmd) {
  get-command $cmd | select path
}

function fuck {
  $fuck = $(thefuck (get-history -count 1).commandline)
  if($fuck.startswith("echo")) {
    $fuck.substring(5)
  }
  else { iex "$fuck" }
}

import-module PSReadline
try { $null = gcm pshazz -ea stop; pshazz init } catch { }

Set-PSReadlineOption -EditMode Emacs

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Load Jump-Location profile
Import-Module 'C:\Users\Mars\Documents\WindowsPowerShell\Modules\Jump.Location\Jump.Location.psd1'

. "D:\bin\encoding-helpers.ps1"

$OutputEncoding = [Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

$PSProfileHome = 'C:\Users\Mars\Documents\WindowsPowerShell'
$E=[char]0x001b; Write-Host "$E`[1;33;40m Yellow on black $E`[0m"
