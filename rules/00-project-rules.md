# NixIDE Project Rules

## Project Patterns

1. **Update Script Structure**
   - Each IDE has its own dedicated update script
   - Scripts follow a common pattern but with package-specific implementations
   - Python is the primary language for update scripts

2. **Version Detection**
   - Each IDE may have a different mechanism for version detection
   - Scripts should handle package-specific version formats
   - Version comparison determines if updates are needed

3. **PR Workflow**
   - Each update generates a separate PR
   - PRs include version change information
   - Successful builds auto-merge, failed builds remain open

4. **Multi-Platform Support**
   - All packages should build on supported architectures
   - Platform-specific configurations are handled in the package definitions
   - Some IDEs may not support all architectures

## Coding Standards

1. **Python Code**
   - Follow PEP 8 style guidelines
   - Use meaningful variable and function names
   - Include docstrings for functions and modules
   - Handle errors gracefully with appropriate logging

2. **Nix Code**
   - Follow nixpkgs coding style
   - Maintain compatibility with nixpkgs structure
   - Preserve comments and formatting from original files

3. **GitHub Workflows**
   - Use clear job and step names
   - Include comments for complex operations
   - Set appropriate timeouts and failure conditions

## Project Preferences

1. **Update Frequency**
   - Check for updates every 4 hours
   - Balance between timeliness and resource usage

2. **Error Handling**
   - Log errors with context for debugging
   - Fail gracefully and continue with other operations when possible
   - Preserve context for manual intervention

3. **Documentation**
   - Keep README up-to-date with current functionality
   - Document troubleshooting steps for common issues
   - Include examples for manual operations when needed

## Known Challenges

1. **Nixpkgs Integration**
   - Nixpkgs structure may change over time
   - Update scripts need to handle these changes gracefully

2. **IDE-Specific Quirks**
   - Each IDE may have unique versioning and packaging
   - Some IDEs may require special handling for certain versions

3. **Cross-Platform Compatibility**
   - Building on macOS may require different approaches
   - Resource limitations on GitHub Actions runners

## Future Considerations

1. **Additional IDEs**
   - The system should be extensible to support more IDEs
   - New update scripts should follow established patterns

2. **Performance Optimization**
   - Caching strategies may need refinement
   - Build times should be monitored and optimized

3. **User Feedback**
   - Consider mechanisms for users to request specific versions
   - Implement notification systems for update status
