# Hermes Launch Helper
# Opens a new PowerShell window with all tools\* subdirectories appended to PATH.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolsDir  = Join-Path $scriptDir "tools"

# Collect all immediate subdirectories under tools/ (ripgrep, ffmpeg, etc.)
$toolPaths = Get-ChildItem -Path $toolsDir -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { $_.FullName }

if (-not $toolPaths) {
    Write-Warning "No tool subdirectories found under: $toolsDir"
}

# Build the PATH fragment to append
$extraPath = $toolPaths -join ";"

# Command that the new PowerShell window will execute on startup:
#   1. Set HERMES_HOME to the package root
#   2. Append tool paths to its own PATH
#   3. Set working directory to the package root
#   4. Print a confirmation banner
$initCommand = @"
`$env:HERMES_HOME = '$scriptDir';
`$env:Path += ';$extraPath';
Set-Location '$scriptDir';
Write-Host 'Hermes environment configured:' -ForegroundColor Green;
Write-Host "  HERMES_HOME: `$env:HERMES_HOME" -ForegroundColor DarkGray;
Write-Host '  Tools added to PATH:' -ForegroundColor DarkGray;
$($toolPaths | ForEach-Object { "Write-Host '    $_' -ForegroundColor DarkGray" } | Out-String)
Write-Host '';
"@

Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $initCommand
