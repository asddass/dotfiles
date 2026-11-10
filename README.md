# dotfiles

Cross-platform development environment for Windows (PowerShell) and Linux/WSL (Ubuntu).

## Directory Structure

```text
dotfiles/
├── linux/
│   ├── ubuntu-dev-bootstrap.sh  # Automated setup script for Ubuntu/WSL
│   └── bashrc.d/
│       └── dev-wrappers.sh      # Custom shell wrappers & package manager restrictions
├── windows/
│   ├── install.ps1              # Profile stub injector & dynamic .wslconfig setup
│   ├── Microsoft.PowerShell_profile.ps1
│   └── scripts/
│       ├── Get-GitStatus.ps1            # Batch Git repository status checker
│       ├── Export-GitHubIssueTree.ps1   # GitHub issue & sub-issue exporter
│       └── Find-Text.ps1                # Dependency-free text finder
├── .gitattributes               # Line-ending normalization (LF vs CRLF)
└── .gitignore                   # Repo-level ignore rules
```

## Quick Start

### 1. Windows (PowerShell)

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
winget install --id Git.Git -e
```

Open a new terminal, then:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\repos" | Out-Null
git clone https://github.com/asddass/dotfiles.git $env:USERPROFILE\repos\dotfiles
& "$env:USERPROFILE\repos\dotfiles\windows\install.ps1"
```

Open another new terminal. If WSL is running, execute `wsl --shutdown` to apply the `.wslconfig` settings.

### 2. Linux / WSL (Ubuntu)

The bootstrap script installs `gh`, `fnm`, `uv`, OpenCode, Node.js LTS, and `pnpm`, and configures `~/.bashrc` to load the scripts in `bashrc.d/`.

On WSL, it also disables Windows PATH injection and, if the Windows `%USERPROFILE%\.agents` directory exists, creates a link to it at `~/.agents`.

If Ubuntu is not already installed on WSL, install it first:
```powershell
wsl --install -d Ubuntu
```

On first launch, Ubuntu prompts you to create a Linux user. Then, in the Ubuntu terminal, run:

```bash
sudo apt-get update && sudo apt-get install -y git
mkdir -p ~/repos && git clone https://github.com/asddass/dotfiles.git ~/repos/dotfiles
bash ~/repos/dotfiles/linux/ubuntu-dev-bootstrap.sh
```

On WSL, the script bridges your Windows Git Credential Manager login to `gh` when possible.

Follow the final instructions displayed by the script to complete the setup and apply all changes.

*Keep the repository at `~/repos/dotfiles`, as `~/.bashrc` references this path directly.*

## Usage

**PowerShell:**

- `GitStatus [path] [-All] [-Help]`: Scans subdirectories for uncommitted Git changes
- `Export-GitHubIssueTree -IssueNumber N [-OutputPath file]`: Exports an issue tree to JSON. Defaults to `.temp\issue-N.json` (requires `gh`)
- `Find-Text "query" [path] [-Context N] [-MaxResults N] [-ExcludeDirectory names]`: Context-aware search with directory exclusions. **Not intended for large directories.**
- `Edit-Profile` / `Reload-Profile`: Quick access to edit or reload the PowerShell profile.
- `ll`: Runs `Get-ChildItem -Force`.

**Bash:**

- `npm install`, `yarn`, and `pip install` are blocked. Use `pnpm` and `uv` instead.
- `fd` is aliased to `fdfind`.
- Shell sessions started from `/mnt/c/Users/...` automatically switch to `~`.
- Drop any `.sh` file into `linux/bashrc.d/` to automatically load it in new shells.