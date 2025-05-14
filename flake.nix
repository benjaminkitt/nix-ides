{
  description = "Automated updates for popular IDE packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Helper function to import package definitions
        importPkg = path: import path { inherit pkgs; };
      in
      {
        packages = {
          # VS Code packages
          vscode = importPkg ./pkgs/vscode/stable;
          vscode-insiders = importPkg ./pkgs/vscode/insiders;
          
          # Windsurf package
          windsurf = importPkg ./pkgs/windsurf/stable;
          
          # Cursor package
          cursor = importPkg ./pkgs/cursor/stable;
          
          # Zed packages
          zed = importPkg ./pkgs/zed/stable;
          zed-prerelease = importPkg ./pkgs/zed/prerelease;
          
          # Default package
          default = self.packages.${system}.vscode;
        };
      }
    );
}
