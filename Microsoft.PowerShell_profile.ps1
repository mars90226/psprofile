$OutputEncoding = [Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

$PSProfileHome = 'C:\Users\Mars\Documents\WindowsPowerShell'
$E=[char]0x001b # Usage: Write-Host "$E`[1;33;40m Yellow on black $E`[0m"

try { $null = gcm pshazz -ea stop; pshazz init } catch { }

# Load PSReadline module
Import-Module PSReadline
Set-PSReadlineOption -EditMode Emacs
. "C:\Program Files\WindowsPowerShell\Modules\PSReadline\1.2\SamplePSReadlineProfile.ps1"
Set-PSReadlineKeyHandler -Key Ctrl+LeftArrow -Function ShellBackwardWord
Set-PSReadlineKeyHandler -Key Ctrl+RightArrow -Function ShellForwardWord

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Load PSFzf
Remove-PSReadlineKeyHandler -Key Ctrl+R
Import-Module PSFzf

# Load Fasdr
#Import-Module Fasdr
# There is a bug to prevent Tab to complete

# Load ZLocation
Import-Module ZLocation

# Load PSEverything
Import-Module PSEverything

# Load encoding-helpers
. "$PSProfileHome\encoding-helpers.ps1"

# Set EDITOR=vim
$env:EDITOR = "vim"

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

# fzf open Firefox history
function ffh([switch] $full) {
	$LIMIT = 10000
	$FIREFOX_PROFILE = "C:\Users\Mars\AppData\Roaming\Mozilla\Firefox\Profiles\qbjj0r7t.default"
	$cols = [Math]::Floor([Console]::WindowWidth / 3)
	$limit = if ($full) { "" } else { " limit $LIMIT" }
	$query = "select substr(title, 1, $cols), url from moz_places order by last_visit_date desc$limit;"

	sqlite3 -separator '{::}' $FIREFOX_PROFILE\places.sqlite $query |
	%{ $name, $url = $_ -split '{::}'; "{0,$cols} $E`[36m{1}$E`[0m" -f $name, $url } |
	fzf --ansi --multi |
	%{ $_ -replace ".*(https*://)", '$1' } |
	%{ & 'C:\Program Files\Mozilla Firefox\firefox.exe' $_ }
}

# fzf open Firefox bookmarks
function ffb {
	$FIREFOX_PROFILE = "C:\Users\Mars\AppData\Roaming\Mozilla\Firefox\Profiles\qbjj0r7t.default"
	$cols = [Math]::Floor([Console]::WindowWidth / 3)
	$query = "select substr(moz_bookmarks.title, 1, $cols), url from moz_bookmarks join moz_places on moz_bookmarks.fk == moz_places.id order by moz_bookmarks.title desc;"

	sqlite3 -separator '{::}' $FIREFOX_PROFILE\places.sqlite $query |
	%{ $name, $url = $_ -split '{::}'; "{0,$cols} $E`[36m{1}$E`[0m" -f $name, $url } |
	fzf --ansi --multi |
	%{ $_ -replace ".*(https*://)", '$1' } |
	%{ & 'C:\Program Files\Mozilla Firefox\firefox.exe' $_ }
}

