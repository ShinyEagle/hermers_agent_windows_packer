# Hermes Agent Windows Packer

A GitHub Actions workflow repository that automatically packages the [Hermes Agent](https://github.com/NousResearch/hermes-agent) into a ready-to-use, self-contained **Windows archive**.

> 💡 **Built entirely from source.** This packer produces a ready-to-run Windows
> application for **every** qualifying upstream release, **regardless of whether
> hermes-agent itself publishes any Windows release or binaries**. The upstream
> release list is only used to decide *which* version to package; the actual
> build runs the official installer on the source inside CI.

Every hour the workflow checks the upstream [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) repository for new releases. When it finds a version that hasn't been packaged yet, it verifies `install.ps1` integrity against the official distribution, downloads portable tools (ripgrep, ffmpeg), runs the installer inside a clean `HERMES_HOME`, and publishes everything as a single `.7z` archive in a GitHub Release — users just extract it and run `hermes-launch.ps1`.

---

## Table of Contents

- [How It Works](#how-it-works)
- [Triggers](#triggers)
- [Naming Conventions](#naming-conventions)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
- [Files](#files)
- [Customization](#customization)
- [FAQ](#faq)

---

## How It Works

The pipeline consists of 10 steps inside [`package.yml`](.github/workflows/package.yml):

| Step | Name | What it does |
|------|------|--------------|
| 1 | Determine version | Manual runs use the provided tag/branch. Scheduled runs query the upstream GitHub API, keep stable releases published after **2026-08-01**, and pick the newest one that has no Windows build yet. If nothing is new, it sets `skip=true`. |
| 1b | Skip gate | Propagates Step 1's skip decision and (for scheduled runs) double-checks that today's release doesn't already exist, guarding against racing runs. All later steps run only when `skip != 'true'`. |
| 2 | Checkout | Checks out **this** repository (which mirrors hermes-agent) at the chosen tag/branch. |
| 3 | Verify & patch install.ps1 | Compares the repo copy of `install.ps1` against the official one from `hermes-agent.nousresearch.com` (SHA-256; a mismatch is currently a warning). Then removes the PATH-reset line that would wipe the tool paths and saves the result as `install.new.ps1`. |
| 4 | Download tools | Fetches the latest portable **ripgrep** and **ffmpeg** from GitHub releases into `hermes\tools\`. |
| 5 | Install | Runs `install.new.ps1 -IncludeDesktop` with a minimal, controlled `PATH` and `HERMES_HOME` pointing into the workspace, so the whole installation is captured. |
| 6 | Package contents | Copies `hermes-launch.ps1` (and any extra files) into the package. |
| 7 | Package with 7z | Compresses `hermes\` into `hermes-agent-windows-<timestamp>-<version>.7z` (`-mx=5`). |
| 8 | Upload artifact | Uploads the archive as a build artifact (retained 7 days). |
| 9 | Create Release | Creates a GitHub Release in this repository with the archive (or uploads into an existing one on re-runs). |

## Triggers

| Trigger | When | Behavior |
|---------|------|----------|
| `schedule` (`0 * * * *`) | Every hour at minute 0 | Finds the newest unbuilt upstream release (≥ 2026-08-01, non-prerelease) and builds it. Skips cleanly when everything is up to date. |
| `workflow_dispatch` | Manual | Builds the given tag/branch on demand, even if already built. |

Manual trigger inputs:

| Input | Description | Default |
|-------|-------------|---------|
| `hermes_tag` | hermes-agent tag to build (takes precedence) | *(empty)* |
| `hermes_branch` | hermes-agent branch to build | `main` |

## Naming Conventions

- **Release tag:** `hermes-agent-windows-<yyyyMMdd>-<version>` (build date)
- **Archive name:** `hermes-agent-windows-<yyyyMMddHHmmss>-<version>.7z`
- **Release title:** `Hermes Agent Windows <yyyyMMdd> (<version>)`

---

## Directory Structure

### This Repository (Source)

```
hermers_agent_windows_packer/
├── .github/
│   └── workflows/
│       └── package.yml          # CI workflow definition (the whole pipeline)
├── hermes-launch.ps1            # Launcher script (shipped inside the package)
├── install.ps1                  # Mirror copy of the upstream installer
└── README.md
```

> `install.new.ps1` is generated at build time (Step 3) from the official
> `install.ps1` — it is not checked into the repo.

### Built Package (after extraction)

### Built Package (after extraction)

```
<extracted folder>/
├── hermes-launch.ps1            # Launcher — sets HERMES_HOME, adds tools\* to PATH
├── tools/
│   ├── ripgrep/                 # Portable ripgrep (rg.exe)
│   └── ffmpeg/                  # Portable ffmpeg (ffmpeg.exe)
│
├── hermes-agent/                # Full Hermes installation
│   ├── .hermes-bootstrap-complete
│   ├── hermes_cli/              # Python CLI package
│   ├── venv/
│   │   └── Scripts/
│   │       ├── hermes.exe       # CLI launcher (hermes <command>)
│   │       └── python.exe       # Managed Python interpreter
│   ├── apps/
│   │   └── desktop/
│   │       └── release/
│   │           └── win-unpacked/
│   │               └── Hermes.exe   # ← Desktop GUI application
│   ├── node_modules/            # Browser tools dependencies
│   ├── skills/                  # Bundled AI skill definitions
│   └── tools/
│       └── skills_sync.py       # Skill synchronization script
│
├── .env                         # API keys, model configuration
├── SOUL.md                      # AI personality prompt
├── skills/                      # Synced skills
└── whatsapp/                    # WhatsApp integration data
```

> The archive contains the full contents of `HERMES_HOME` (the `hermes\`
> directory built in CI), so user-data files like `.env` are included as
> templates. Fill in your own API keys before first use.

---

## Usage

### Automatic Builds

The workflow runs **every hour** (`cron: '0 * * * *'`). It queries the upstream
hermes-agent releases, and if a stable release published on/after 2026-08-01
has no Windows build yet, it builds and publishes it. Otherwise the run exits
early without consuming significant runner time.

### Manual Trigger

Go to **Actions → Build and Release Hermes Agent → Run workflow** and optionally
set `hermes_tag` (preferred, e.g. `v1.2.3`) or `hermes_branch`. Manual runs
always build, even if the version was packaged before.

### Using the Package

1. Download the latest `hermes-agent-windows-*.7z` from the [Releases page](../../releases).
2. Extract the archive to your preferred location (e.g. `C:\Hermes`).
3. Run `hermes-launch.ps1` — it opens a new PowerShell window with `HERMES_HOME`
   set and all `tools\*` directories on `PATH`, ready to use.
---

## Files

| File | Purpose |
|------|---------|
| `.github/workflows/package.yml` | GitHub Actions workflow — defines the full build pipeline |
| `.github/workflows/package.yml` | GitHub Actions workflow — defines the full build pipeline |
| `hermes-launch.ps1` | Portable launcher — sets `HERMES_HOME`, adds `tools\*` to `PATH` and opens a ready-to-use PowerShell window |
| `install.ps1` | Mirror of the upstream installer, used for the integrity check in Step 3 |

## Customization

### Build cutoff date

Only upstream releases published on/after **2026-08-01** are considered. To
change the window, edit `$cutoffDate` in Step 1 of `package.yml`.

### Adding More Tools

Edit **Step 4** in `package.yml` to download additional portable tools:

```powershell
# Example: adding a new tool
$toolRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/OWNER/REPO/releases/latest"
$toolAsset = $toolRelease.assets | Where-Object { $_.name -match "PATTERN" }
Invoke-WebRequest -Uri $toolAsset.browser_download_url -OutFile "tool.zip"
Expand-Archive -Path "tool.zip" -DestinationPath "$ToolsDir\tool-tmp" -Force
$innerDir = Get-ChildItem "$ToolsDir\tool-tmp" -Directory | Select-Object -First 1
Move-Item -Path $innerDir.FullName -Destination "$ToolsDir\tool"
Remove-Item "tool.zip", "$ToolsDir\tool-tmp" -Recurse -Force
```

The tool will automatically be available in the launched PowerShell session,
because `hermes-launch.ps1` adds every `tools\*` subdirectory to `PATH`.

### Adding Extra Files to the Package

Edit **Step 6** in `package.yml`:

```powershell
Copy-Item "$RootDir\my-config.json" "$HermesDir\" -Force
```

## FAQ

**Q: What if the upstream hermes-agent release has no Windows binaries?**
That's exactly what this packer is for. The Windows package is built entirely
from source inside CI (checkout → official installer → portable tools → 7z),
so a ready-to-run Windows archive is produced even when the upstream release
contains no Windows assets at all.

**Q: Why is `install.ps1` patched instead of run as-is?**
The official script resets `$env:Path` to the user/machine values, which would
drop the `hermes\tools\ripgrep` and `hermes\tools\ffmpeg` paths that the CI
environment needs. The patch removes that single line and saves the result as
`install.new.ps1`.

**Q: What happens if a build fails halfway?**
Steps 8–9 simply don't run, so no partial release is published. The next
scheduled run will detect the version as "not yet built" and try again.

**Q: Can two scheduled runs race and publish duplicate releases?**
The skip gate (Step 1b) checks for an existing release right before building,
and Step 9 uploads with `--clobber` if the release appeared meanwhile