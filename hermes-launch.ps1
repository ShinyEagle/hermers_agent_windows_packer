# Hermes Launch Helper
# Opens a new PowerShell window with all tools\* subdirectories appended to PATH.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$hermesDir = Join-Path $scriptDir "hermes-agent"
$toolsDir  = Join-Path $scriptDir "tools"
$dependenciesList= @(
    "git",
    "node",
    "python",
    "bin"
)
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
#   3. Point Playwright at the browsers folder shipped inside the package
#      (set during install via PLAYWRIGHT_BROWSERS_PATH; kept inside the
#      archive so browser tools work right after extraction)
#   4. Set working directory to the package root
#   5. Print a confirmation banner
$dependenciesAbsDirs = $dependenciesList | ForEach-Object { Join-Path -Path $scriptDir -ChildPath $_ }
$depPaths = $dependenciesAbsDirs -join ";"
$venvPath = Join-Path -Path $hermesDir -ChildPath "venv\Scripts"

$initCommand = @"
`$env:HERMES_HOME = '$scriptDir';
`$env:Path = '$extraPath;$depPaths;$venvPath;' + `$env:Path;
`$env:venvPath = '$venvPath';
if (Test-Path '$scriptDir\browsers') { `$env:PLAYWRIGHT_BROWSERS_PATH = '$scriptDir\browsers' };
Set-Location '$scriptDir';
Write-Host 'Hermes environment configured:' -ForegroundColor Green;
Write-Host "  HERMES_HOME: `$env:HERMES_HOME" -ForegroundColor DarkGray;
Write-Host '  Tools added to PATH:' -ForegroundColor DarkGray;
$($toolPaths | ForEach-Object { "Write-Host '    $_' -ForegroundColor DarkGray" } | Out-String)
Write-Host '  Dependencies added to PATH:' -ForegroundColor DarkGray;
$($dependenciesAbsDirs | ForEach-Object { "Write-Host '    $_' -ForegroundColor DarkGray" } | Out-String)
Write-Host ''; Write-Host "  PLAYWRIGHT_BROWSERS_PATH: `$env:PLAYWRIGHT_BROWSERS_PATH" -ForegroundColor DarkGray;
$venvPath\activate.ps1
"@


Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $initCommand

