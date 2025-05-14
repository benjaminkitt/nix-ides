# NixIDE: Automated IDE Update Repository

## Project Overview

NixIDE is a GitHub repository that automatically updates popular IDE and editor packages by:
1. Fetching the latest build definitions from nixpkgs
2. Updating them to the newest available versions 
3. Creating individual PRs for review and automatic testing

## Core Functionality

1. **IDE Coverage**:
   - VS Code (stable + insiders)
   - Windsurf (stable)
   - Cursor (stable)
   - Zed (stable + prerelease)

2. **Automated Update Process**:
   - Check for new editor versions every 4 hours
   - Pull nixpkgs build files only when updates are needed
   - Create separate PRs for each updated package
   - Auto-merge successful builds to main
   - Keep failed build PRs open for manual intervention

3. **Architecture Support**:
   - linux-x86_64
   - darwin-aarch64
   - darwin-x86_64 (where available)

## Repository Structure

```
nixide/
├── flake.nix                 # Main entry point exposing all IDEs
├── README.md                 # Documentation
├── .github/workflows/        
│   ├── update-check.yml      # Scheduled version check (every 4 hours)
│   └── pr-build-test.yml     # PR validation workflow
├── pkgs/                     # Package definitions (populated by update scripts)
│   ├── vscode/
│   │   ├── stable/           # Files from nixpkgs with updated versions
│   │   └── insiders/         # Files from nixpkgs with updated versions
│   ├── windsurf/
│   │   ├── stable/           # Files from nixpkgs with updated versions
│   ├── cursor/
│   │   └── stable/           # Files from nixpkgs with updated versions
│   └── zed/
│       ├── stable/           # Files from nixpkgs with updated versions
│       └── prerelease/       # Files from nixpkgs with updated versions
└── scripts/                  # Update automation scripts
    ├── update-vscode.sh      # Handles both stable and insiders versions
    ├── update-windsurf.sh    # Handles both stable and next versions
    ├── update-cursor.sh      # Handles stable version
    └── update-zed.sh         # Handles both stable and prerelease versions
```

## Implementation Details

The project includes:
- Python scripts for fetching and updating package definitions
- GitHub workflows for automated testing and merging
- Integration with Cachix for binary caching
- Support for multiple platforms and architectures

## Key Design Decisions

1. **Optimized Synchronization Approach**
   - Only fetches nixpkgs files when updates are needed
   - Reduces redundancy and resource usage
   - Maintains clear commit history

2. **Package-Specific Version Detection**
   - Flexible design with package-specific update strategies
   - Future-proof approach to handle changes in upstream packages
   - Maintainable code with isolated update logic

3. **Manual Intervention Workflow**
   - Failed builds remain as open PRs for review
   - Preserves context for debugging
   - Enables manual fixes while maintaining automation
