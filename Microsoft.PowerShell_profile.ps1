# PowerShell profile, shared via dotfiles. Every import and tool hookup is
# guarded so the same file works on Windows and in a Linux codespace where
# most of the modules are not installed.

foreach ($m in 'Terminal-Icons', 'PSScriptAnalyzer', 'PSWindowsUpdate', 'Microsoft.Graph.Users') {
  if (Get-Module -ListAvailable -Name $m) { Import-Module $m }
}
if ($env:ChocolateyInstall -and (Test-Path "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1")) {
  Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
}

# VS Code spawns pwsh directly, so the PATH additions setup.sh puts in
# ~/.bashrc never run here. Add ~/.local/bin ourselves on Linux.
if (-not $IsWindows) {
  $localBin = Join-Path $HOME '.local/bin'
  if ((Test-Path $localBin) -and (($env:PATH -split ':') -notcontains $localBin)) {
    $env:PATH = "${localBin}:$env:PATH"
  }
}

Import-Module PSReadLine
# Prediction needs a real VT console; stay quiet when output is redirected
# (VS Code tasks, CI) so a profile load never prints errors.
try {
  Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
  Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
} catch {}
Set-PSReadLineOption -EditMode Windows
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# https://docs.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete#powershell
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
  Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
  }
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  # setup.sh links the theme at ~/; older machines keep it under ~/.config.
  $ompConfig = "$HOME/.vityusha-ohmyposhv3-v2.json", "$HOME/.config/vityusha-ohmyposhv3-v2.json" |
    Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($ompConfig) { oh-my-posh init pwsh --config $ompConfig | Invoke-Expression }
}

# Open the one solution file in the current directory with Visual Studio's
# launcher. A lone .slnx wins over .sln, so a repo mid-migration that still
# carries both opens the new format. Windows only: containers have no VS.
if ($IsWindows) {
function sln {
    $solutions = @(Get-ChildItem -File | Where-Object Extension -In '.slnx', '.sln')
    $slnx = @($solutions | Where-Object Extension -EQ '.slnx')
    $target = if ($solutions.Count -eq 1) { $solutions[0] }
              elseif ($slnx.Count -eq 1) { $slnx[0] }
    if ($target) { Invoke-Item $target.FullName; return }
    if ($solutions.Count -eq 0) { Write-Error "No .sln or .slnx file in $PWD" }
    else { Write-Error "More than one solution in ${PWD}: $($solutions.Name -join ', ')" }
}
}
