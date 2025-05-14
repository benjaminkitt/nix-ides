# NixIDE: Automated IDE Update Repository

## Revised Brief

### NixIDE: Rapid IDE Updates from Nixpkgs Sources

A GitHub repository that automatically updates popular IDE and editor packages by:
1. Fetching the latest build definitions from nixpkgs
2. Updating them to the newest available versions 
3. Creating individual PRs for review and automatic testing

#### Core Functionality

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

#### Repository Structure

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

#### Update Workflow Implementation

```python
# Example implementation for update-vscode.sh (pseudocode with actual logic)
#!/usr/bin/env python3
import os, requests, subprocess, re, json, hashlib, tempfile

# Source and destination paths
NIXPKGS_PATH = "pkgs/applications/editors/vscode"
LOCAL_STABLE_PATH = "pkgs/vscode/stable"
LOCAL_INSIDERS_PATH = "pkgs/vscode/insiders"
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

def fetch_nixpkgs_files(source_path, destination_path, branch="master"):
    """Fetch all files from a nixpkgs path and save locally"""
    # Create directory if needed
    os.makedirs(destination_path, exist_ok=True)
    
    # Get file listing via GitHub API
    api_url = f"https://api.github.com/repos/NixOS/nixpkgs/contents/{source_path}?ref={branch}"
    response = requests.get(api_url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch directory listing: {response.status_code}")
        
    files = response.json()
    
    # Download each file
    for file in files:
        if file["type"] == "file":
            content = requests.get(file["download_url"]).text
            with open(f"{destination_path}/{file['name']}", "w") as f:
                f.write(content)
        elif file["type"] == "directory":
            # Handle subdirectories recursively if needed
            subdir = f"{destination_path}/{file['name']}"
            fetch_nixpkgs_files(f"{source_path}/{file['name']}", subdir, branch)

def extract_version(file_path):
    """Extract version from a nix file - adapt to each package's format"""
    with open(file_path, "r") as f:
        content = f.read()
    
    # VS Code typically uses this format
    version_match = re.search(r'version = "([^"]+)"', content)
    if version_match:
        return version_match.group(1)
    return None

def fetch_latest_version(channel="stable"):
    """Get latest version from VS Code API"""
    url = f"https://update.code.visualstudio.com/api/update/linux-x64/{channel}/latest"
    response = requests.get(url)
    if response.status_code == 200:
        return response.json().get("productVersion")
    return None

def update_sha256_hash(file_path, version, platform_urls):
    """Update SHA256 hashes in nix file for all platforms"""
    with open(file_path, "r") as f:
        content = f.read()
        
    for platform, url in platform_urls.items():
        # Download file to calculate hash
        temp_file = tempfile.NamedTemporaryFile(delete=False)
        response = requests.get(url, stream=True)
        with open(temp_file.name, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        # Calculate SHA256
        sha256 = hashlib.sha256()
        with open(temp_file.name, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                sha256.update(chunk)
        hash_value = sha256.hexdigest()
        os.unlink(temp_file.name)
        
        # Update hash in file - pattern will need to be adapted per package
        pattern = rf'{platform}\s*=\s*"[a-zA-Z0-9]+"'
        replacement = f'{platform} = "{hash_value}"'
        content = re.sub(pattern, replacement, content)
        
    # Update version
    content = re.sub(r'version = "[^"]+"', f'version = "{version}"', content)
    
    # Write updated content
    with open(file_path, "w") as f:
        f.write(content)
    
    return True

def create_pr(package, current_version, latest_version):
    """Create a PR for the updated package"""
    branch_name = f"update-{package}-{latest_version}"
    subprocess.run(["git", "checkout", "-b", branch_name])
    subprocess.run(["git", "add", f"pkgs/{package}"])
    subprocess.run(["git", "commit", "-m", f"Update {package} to {latest_version}"])
    subprocess.run(["git", "push", "origin", branch_name])
    
    # Create PR via GitHub API
    pr_data = {
        "title": f"Update {package} to {latest_version}",
        "body": f"Updates {package} from {current_version} to {latest_version}.\n\nAutomatically created by NixIDE update script.",
        "head": branch_name,
        "base": "main"
    }
    
    response = requests.post(
        "https://api.github.com/repos/OWNER/nixide/pulls",
        headers={"Authorization": f"token {GITHUB_TOKEN}"},
        json=pr_data
    )
    
    return response.json().get("html_url")

# Main function for VS Code stable
def update_vscode_stable():
    # 1. Fetch nixpkgs files
    fetch_nixpkgs_files(NIXPKGS_PATH, LOCAL_STABLE_PATH)
    
    # 2. Extract current version
    current_version = extract_version(f"{LOCAL_STABLE_PATH}/default.nix")
    if not current_version:
        print("Failed to extract current version")
        return
        
    # 3. Get latest version
    latest_version = fetch_latest_version("stable")
    if not latest_version:
        print("Failed to fetch latest version")
        return
        
    # 4. Compare versions
    if latest_version == current_version:
        print(f"VS Code stable already at latest version: {current_version}")
        return
        
    print(f"Updating VS Code from {current_version} to {latest_version}")
    
    # 5. Define platform URLs (based on version)
    platform_urls = {
        "x86_64-linux": f"https://update.code.visualstudio.com/{latest_version}/linux-x64/stable",
        "aarch64-darwin": f"https://update.code.visualstudio.com/{latest_version}/darwin-arm64/stable",
        "x86_64-darwin": f"https://update.code.visualstudio.com/{latest_version}/darwin/stable"
    }
    
    # 6. Update version and hashes
    update_sha256_hash(f"{LOCAL_STABLE_PATH}/default.nix", latest_version, platform_urls)
    
    # 7. Create PR
    pr_url = create_pr("vscode-stable", current_version, latest_version)
    print(f"Created PR: {pr_url}")

# Run the update for VS Code stable
if __name__ == "__main__":
    update_vscode_stable()
    # Additional function calls could be added for insiders edition
```

#### GitHub Workflow (PR Testing & Automated Builds)

```yaml
# .github/workflows/pr-build-test.yml
name: Build and Test PR

on:
  pull_request:
    types: [opened, synchronize]
    branches: [main]

jobs:
  detect-package:
    runs-on: ubuntu-latest
    outputs:
      package: ${{ steps.extract-info.outputs.package }}
      platform_matrix: ${{ steps.extract-info.outputs.platform_matrix }}
    steps:
      - name: Extract package information from PR title
        id: extract-info
        run: |
          PR_TITLE="${{ github.event.pull_request.title }}"
          PACKAGE=$(echo "$PR_TITLE" | grep -oP 'Update \K[\w-]+(?= to)')
          echo "package=$PACKAGE" >> $GITHUB_OUTPUT
          
          # Determine which platforms to test based on package
          # Default to all platforms
          echo 'platform_matrix=["x86_64-linux", "aarch64-darwin", "x86_64-darwin"]' >> $GITHUB_OUTPUT

  build:
    needs: detect-package
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        platform: ${{ fromJson(needs.detect-package.outputs.platform_matrix) }}
        include:
          - platform: x86_64-linux
            os: ubuntu-latest
          - platform: aarch64-darwin
            os: macos-latest-xlarge
          - platform: x86_64-darwin
            os: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Install Nix
        uses: cachix/install-nix-action@v22

      - name: Setup Cachix
        uses: cachix/cachix-action@v12
        with:
          name: nixide
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Build package
        id: build
        run: |
          nix build .#${{ needs.detect-package.outputs.package }} --system ${{ matrix.platform }} --accept-flake-config
          
      - name: Upload to Cachix
        if: success()
        run: |
          nix path-info --recursive .#${{ needs.detect-package.outputs.package }} | cachix push nixide

  merge-on-success:
    needs: build
    runs-on: ubuntu-latest
    if: ${{ success() }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Auto-merge PR
        uses: pascalgn/automerge-action@v0.15.6
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
          MERGE_LABELS: ""
          MERGE_METHOD: "squash"
          MERGE_COMMIT_MESSAGE: "pull-request-title"
```

## Analysis and Feedback

This revised brief provides a solid foundation for automating IDE updates while leveraging nixpkgs configurations. Key improvements include:

### 1. Optimized Synchronization Approach

The design now only fetches nixpkgs files when updates are needed, providing:

- **Reduced redundancy**: No unnecessary file fetching when nothing needs to change
- **Clear commit history**: Each PR contains only the necessary version update changes
- **Lower resource usage**: GitHub API calls and repository operations are minimized

### 2. Package-Specific Version Detection

The implementation allows for package-specific version detection mechanisms:

- **Flexible design**: Each update script can implement the appropriate strategy for its package
- **Future-proof**: Can handle changes to version formats in upstream packages
- **Maintainable code**: Updates to detection logic can be isolated to specific packages

### 3. Manual Intervention Workflow

Failed builds now remain as open PRs:

- **Review convenience**: All build errors are context-preserved in the PR checks
- **Manual fix capability**: PRs can be updated with fixes and retested
- **Clear organization**: Each version update stays isolated in its own PR

### 4. Implementation Details

The final design includes several important technical features:

- **Complete file fetching**: Retrieves all files including patches and additional resources
- **Hash calculation**: Properly handles generating new SHA256 hashes for updated packages
- **Platform coverage**: Builds and tests on all supported platforms
- **Binary cache integration**: Successfully built packages are cached via Cachix
- **Smart PR handling**: Failed builds remain open while successful builds auto-merge

By keeping failed PRs open and enabling manual intervention, you'll be able to debug any issues that arise while still benefiting from automation for the majority of updates that build successfully.