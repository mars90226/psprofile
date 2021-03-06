# Bootstrap
# --------------------------------------------------------------------

# Setup scoop git
[environment]::setenvironmentvariable('GIT_SSH', (resolve-path (scoop which ssh)), 'USER')

$OutputEncoding = [Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

$PSProfileHome = 'C:\Users\Mars\Documents\WindowsPowerShell'
$BIN='D:\bin'
$E=[char]0x001b # Usage: Write-Host "$E`[1;33;40m Yellow on black $E`[0m"

# Plugins
# --------------------------------------------------------------------

try { $null = gcm pshazz -ea stop; pshazz init } catch { }

# Load PSReadline module
Import-Module PSReadline
Set-PSReadlineOption -EditMode Emacs
. "$PSProfileHome\SamplePSReadlineProfile.ps1"
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

# Load Posh-Git
Import-Module Posh-Git
if (!(Get-Process -Name ssh-agent)) {
	Start-SshAgent -Quiet
}

# Load encoding-helpers
. "$PSProfileHome\encoding-helpers.ps1"

# Settings
# --------------------------------------------------------------------

# Set EDITOR=vim
$env:EDITOR = "vim"

# Set FZF
if (Get-Command "fd" -ErrorAction SilentlyContinue) {
	$env:FZF_DEFAULT_COMMAND = 'fd --no-ignore --hidden --follow --exclude .git --exclude node_modules'
	$env:FZF_ALT_C_COMMAND = 'fd --type d --no-ignore --hidden --follow --exclude .git --exclude node_modules'
}
$env:FZF_DEFAULT_OPTS = '
  --bind=alt-j:page-down
  --bind=alt-k:page-up
'

# Alias
# --------------------------------------------------------------------

If (Test-Path Alias:fd) {
	Remove-Item Alias:fd
}
Set-Alias -Name fdd -Value Invoke-FuzzySetLocation

# Functions
# --------------------------------------------------------------------

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

function firefox($url) {
	& 'D:\Program Files (x86)\Firefox Developer Edition\firefox.exe' $url
}

function chrome($url) {
	& 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' $url
}

# FZF
# --------------------------------------------------------------------

# fzf open Firefox history
function ffh([switch] $full) {
	$LIMIT = 10000
	$FIREFOX_PROFILE = "$env:APPDATA\Mozilla\Firefox\Profiles\qbjj0r7t.default"
	$cols = [Math]::Floor([Console]::WindowWidth / 3)
	$sep = '{::}'
	$limit = if ($full) { "" } else { " limit $LIMIT" }
	$query = "select substr(title, 1, $cols), url from moz_places order by last_visit_date desc$limit;"

	sqlite3 -separator $sep $FIREFOX_PROFILE\places.sqlite $query |
	%{ $name, $url = $_ -split $sep; "{0,$cols} $E`[36m{1}$E`[m" -f $name, $url } |
	fzf --ansi --multi |
	%{ $_ -replace ".*(https*://)", '$1' } |
	%{ firefox $_ }
}

# fzf open Firefox bookmarks
function ffb {
	$FIREFOX_PROFILE = "$env:APPDATA\Mozilla\Firefox\Profiles\qbjj0r7t.default"
	$cols = [Math]::Floor([Console]::WindowWidth / 3)
	$sep = '{::}'
	$query = "select substr(moz_bookmarks.title, 1, $cols), url from moz_bookmarks join moz_places on moz_bookmarks.fk == moz_places.id order by moz_bookmarks.title desc;"

	sqlite3 -separator $sep $FIREFOX_PROFILE\places.sqlite $query |
	%{ $name, $url = $_ -split $sep; "{0,$cols} $E`[36m{1}$E`[m" -f $name, $url } |
	fzf --ansi --multi |
	%{ $_ -replace ".*(https*://)", '$1' } |
	%{ firefox $_ }
}

# fzf open Google Chrome history
function ch {
	$CHROME_PROFILE = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
	$cols = [Math]::Floor([Console]::WindowWidth / 3)
	$sep = '{::}'
	$query = "select substr(title, 1, $cols), url from urls order by last_visit_time desc$limit;"
	$tmp_history = "C:\tmp\h"
	Copy-Item $CHROME_PROFILE\History $tmp_history
	sqlite3 -separator $sep $tmp_history $query |
	%{ $name, $url = $_ -split $sep; "{0,$cols} $E`[36m{1}$E`[m" -f $name, $url } |
	fzf --ansi --multi |
	%{ $_ -replace ".*(https*://)", '$1' } |
	%{ chrome $_ }
}

# fzf open Google Chrome bookmarks
function cb {
	$cols = [Math]::Floor([Console]::WindowWidth / 3)
	ruby $BIN\b.rb $cols |
	fzf --ansi --multi |
	%{ ($_ -split "`t")[1] } |
	%{ chrome $_ }
}

# FZF & git
# --------------------------------------------------------------------

function Invoke-FzfPsReadlineHandlerExecutable {
	$result = $null

	Get-Command -Type Application |
	Select-Object -ExpandProperty Name |
	Invoke-Fzf | ForEach-Object { $result = $_ }

	if (-not [string]::IsNullOrEmpty($result)) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
	}
}
Set-PSReadlineKeyHandler -Key 'Ctrl+g,Ctrl+e' -ScriptBlock { Invoke-FzfPsReadlineHandlerExecutable }

function Invoke-FuzzyGitFile() {
	# not git repo
	if (!(git rev-parse HEAD 2> $null)) {
		return
	}

	$result = @()

	git -c color.status=always status --short |
	Invoke-Fzf -Ansi -Multi -Bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all' |
	ForEach-Object { $result += $_.substring(3) }

	if ($result -ne $null) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
	}
}
Set-PSReadlineKeyHandler -Key 'Ctrl+g,Ctrl+f' -ScriptBlock { Invoke-FuzzyGitFile }

function Invoke-FuzzyGitBranch() {
	# not git repo
	if (!(git rev-parse HEAD 2> $null)) {
		return
	}

	$result = @()

	git branch -a --color=always |
	Select-String -NotMatch -Pattern '/HEAD\s' |
	Invoke-Fzf -Ansi -Multi -tac -Bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all' |
	ForEach-Object { $result += $_.substring(2) -replace '^remotes/', '' }

	if ($result -ne $null) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
	}
}
Set-PSReadlineKeyHandler -Key 'Ctrl+g,Ctrl+b' -ScriptBlock { Invoke-FuzzyGitBranch }

function Invoke-FuzzyGitTag() {
	# not git repo
	if (!(git rev-parse HEAD 2> $null)) {
		return
	}

	$result = @()

	git tag --sort '-version:refname' |
	Invoke-Fzf -Ansi -Multi -Bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all' |
	ForEach-Object { $result += $_ }

	if ($result -ne $null) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
	}
}
Set-PSReadlineKeyHandler -Key 'Ctrl+g,Ctrl+t' -ScriptBlock { Invoke-FuzzyGitTag }

function Invoke-FuzzyGitLog() {
	# not git repo
	if (!(git rev-parse HEAD 2> $null)) {
		return
	}

	$result = @()

	git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
	Invoke-Fzf -Ansi -Multi -Bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all' |
	Select-String -Pattern "[a-f0-9]{7,}" |
	ForEach-Object { $_.Matches } |
	ForEach-Object { $_.Value } |
	ForEach-Object { $result += $_ }

	if ($result -ne $null) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
	}
}
Set-PSReadlineKeyHandler -Key 'Ctrl+g,Ctrl+h' -ScriptBlock { Invoke-FuzzyGitLog }

function Invoke-FuzzyGitRemote() {
	# not git repo
	if (!(git rev-parse HEAD 2> $null)) {
		return
	}

	$result = @()

	git remote -v |
	ForEach-Object { ($_ -split " ")[0] } |
	Get-Unique |
	Invoke-Fzf -Ansi -Multi -Bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all' |
	ForEach-Object { $result += ($_ -split "`t")[0] }

	if ($result -ne $null) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
	}
}
Set-PSReadlineKeyHandler -Key 'Ctrl+g,Ctrl+r' -ScriptBlock { Invoke-FuzzyGitRemote }
