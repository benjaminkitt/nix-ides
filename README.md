# NixIDE: Automated IDE Update Repository

[![Build Status](https://github.com/benjaminkitt/nix-ides/actions/workflows/pr-build-test.yml/badge.svg)](https://github.com/benjaminkitt/nix-ides/actions/workflows/pr-build-test.yml)

NixIDE is a repository that automatically updates popular IDE and editor packages by fetching the latest build definitions from nixpkgs, updating them to the newest available versions, and creating individual PRs for review and automatic testing.

## Supported IDEs

- VS Code (stable + insiders)
- Windsurf (stable)
- Cursor (stable)
- Zed (stable + prerelease)

## Architecture Support

- linux-x86_64
- darwin-aarch64
- darwin-x86_64 (where available)

## Usage

### With Flakes (recommended)

```nix
# In your flake.nix
inputs = {
  nixide.url = "github:benjaminkitt/nix-ides";
};

# Then in your outputs
packages.vscode = nixide.packages.${system}.vscode;
```

### Without Flakes

```nix
let
  nixide = import (fetchTarball "https://github.com/benjaminkitt/nix-ides/archive/main.tar.gz") {};
in
  # Use the packages
  nixide.vscode
```

## Available Packages

- `vscode`: VS Code stable
- `vscode-insiders`: VS Code insiders
- `windsurf`: Windsurf stable
- `cursor`: Cursor stable
- `zed`: Zed stable
- `zed-prerelease`: Zed prerelease

## Development

### Prerequisites

- Nix with flakes enabled
- Git

### Setup

1. Clone the repository
   ```bash
   git clone https://github.com/benjaminkitt/nix-ides.git
   cd nix-ides
   ```

2. Build a package
   ```bash
   nix build .#vscode
   ```

## How It Works

This repository automatically checks for new IDE versions every 4 hours. When updates are detected, it:

1. Fetches the latest build definitions from nixpkgs
2. Updates them to the newest available versions
3. Creates individual PRs for review and automatic testing
4. Auto-merges successful builds to main
5. Keeps failed build PRs open for manual intervention

## License

MIT