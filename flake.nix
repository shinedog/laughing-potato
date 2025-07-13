{
  description = "Hydra CI/CD for shinedog/laughing-potato";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # Define the main package build
        laughing-potato = pkgs.stdenv.mkDerivation rec {
          pname = "laughing-potato";
          version = "dev";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            # Add build dependencies here based on your project
            # Example common dependencies:
            # gcc
            # cmake
            # pkg-config
          ];

          buildInputs = with pkgs; [
            # Add runtime dependencies here
          ];

          # Configure phase if needed
          configurePhase = ''
            # Add configuration steps if needed
            echo "Configuring laughing-potato..."
          '';

          # Build phase
          buildPhase = ''
            # Add build steps here
            echo "Building laughing-potato..."
            # Example: make all
          '';

          # Install phase
          installPhase = ''
            mkdir -p $out/bin
            # Add installation steps here
            # Example: cp binary $out/bin/
            echo "#!/bin/bash" > $out/bin/laughing-potato
            echo "echo 'Hello from laughing-potato!'" >> $out/bin/laughing-potato
            chmod +x $out/bin/laughing-potato
            echo "Installing laughing-potato..."
          '';

          # Metadata
          meta = with pkgs.lib; {
            description = "Laughing Potato project";
            homepage = "https://github.com/shinedog/laughing-potato";
            license = licenses.mit; # Adjust based on actual license
            maintainers = [];
            platforms = platforms.unix;
          };
        };
      in {
        packages.default = laughing-potato;
        packages.laughing-potato = laughing-potato;

        # Formatter for `nix fmt`
        formatter = pkgs.alejandra;

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Development tools
            git
            alejandra
            # Add other dev tools as needed
          ];

          # Set essential environment variables for --ignore-environment
          shellHook = ''
            # Set up essential environment
            export HOME="''${HOME:-/tmp/nix-shell-home}"
            export USER="''${USER:-nixuser}"
            export SHELL="''${SHELL:-${pkgs.bash}/bin/bash}"
            export PATH="$PATH:${pkgs.coreutils}/bin"

            # Create a temporary home if needed
            if [[ ! -d "$HOME" ]]; then
              mkdir -p "$HOME"
            fi

            # Set up locale to avoid warnings
            export LANG=C.UTF-8
            export LC_ALL=C.UTF-8

            # Set up Git configuration if not present
            if [[ -z "$(git config --global user.name 2>/dev/null)" ]]; then
              echo "Setting up Git configuration for development..."
              git config --global user.name "Developer"
              git config --global user.email "dev@laughing-potato.local"
              echo "Git configured with default identity (can be changed with git config)"
            fi

            echo "Welcome to laughing-potato development environment!"
            echo "HOME: $HOME"
            echo "Git user: $(git config --global user.name) <$(git config --global user.email)>"
            echo "Available tools: git, alejandra"
          '';
        };

        # Override for different systems
        checks = {
          build = self.packages.${system}.default;
        };
      }
    )
    // {
      # Hydra-specific outputs - flat structure optimized for auto-discovery
      hydraJobs = 
        let
          supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
          
          # Create jobs for each system
          mkSystemJobs = system: let
            pkgs = nixpkgs.legacyPackages.${system};
            
            # Main package
            package = self.packages.${system}.default;
            
            # Test job
            tests = pkgs.stdenv.mkDerivation {
              name = "laughing-potato-tests";
              src = ./.;
              
              buildPhase = ''
                echo "Running tests for laughing-potato on ${system}..."
                # Add test commands here
                # Example: make test
                
                # Basic validation that the package can be built
                echo "Validating package structure..."
                ls -la
                
                # Test that the built package works
                echo "Testing package functionality..."
                ${package}/bin/laughing-potato
              '';

              installPhase = ''
                mkdir -p $out
                echo "Tests completed successfully on ${system}" > $out/test-results.txt
                echo "Test run at: $(date)" >> $out/test-results.txt
              '';
            };

            # Documentation build
            docs = pkgs.stdenv.mkDerivation {
              name = "laughing-potato-docs";
              src = ./.;

              nativeBuildInputs = with pkgs; [
                # Add documentation tools if needed
                # pandoc, sphinx, etc.
              ];

              buildPhase = ''
                echo "Building documentation for ${system}..."
                # Add doc build commands here
                
                # Create basic documentation
                mkdir -p docs
                echo "# Laughing Potato Documentation" > docs/README.md
                echo "Built on: $(date)" >> docs/README.md
                echo "System: ${system}" >> docs/README.md
                echo "" >> docs/README.md
                echo "## Package Information" >> docs/README.md
                echo "- Name: ${package.pname}" >> docs/README.md
                echo "- Version: ${package.version}" >> docs/README.md
              '';

              installPhase = ''
                mkdir -p $out/share/doc/laughing-potato
                # Copy documentation files
                if [ -d docs ]; then
                  cp -r docs/* $out/share/doc/laughing-potato/
                fi
                echo "Documentation built successfully on ${system}" > $out/share/doc/laughing-potato/build-info.txt
              '';
            };

            # Format check job
            format-check = pkgs.stdenv.mkDerivation {
              name = "laughing-potato-format-check";
              src = ./.;

              nativeBuildInputs = with pkgs; [
                alejandra
                findutils
              ];

              buildPhase = ''
                echo "Checking code formatting on ${system}..."
                
                # Find and check all .nix files
                find . -name "*.nix" -type f | while read -r file; do
                  echo "Checking format of: $file"
                  alejandra --check "$file" || {
                    echo "Format check failed for $file"
                    exit 1
                  }
                done
                
                echo "All files are properly formatted"
              '';

              installPhase = ''
                mkdir -p $out
                echo "Format check passed on ${system}" > $out/format-check-results.txt
              '';
            };

            # Combined check job
            check = pkgs.stdenv.mkDerivation {
              name = "laughing-potato-check";
              
              buildInputs = [
                package
                tests
                docs
                format-check
              ];
              
              buildPhase = ''
                echo "Running all checks for laughing-potato on ${system}..."
                echo "All individual checks have passed"
              '';
              
              installPhase = ''
                mkdir -p $out
                echo "All checks completed successfully on ${system}" > $out/all-checks-results.txt
                echo "Build artifacts available" >> $out/all-checks-results.txt
              '';
            };
            
          in {
            # Main build job - use simple naming that Hydra expects
            "${system}" = package;
            "tests.${system}" = tests;
            "docs.${system}" = docs;
            "format-check.${system}" = format-check;
            "check.${system}" = check;
          };
          
          # Generate jobs for all systems
          allSystemJobs = nixpkgs.lib.fold (system: acc: 
            acc // (mkSystemJobs system)
          ) {} supportedSystems;
          
        in allSystemJobs // {
          # Add aggregate jobs that Hydra can use
          build = nixpkgs.lib.genAttrs supportedSystems (system: 
            self.packages.${system}.default
          );
          
          # Release job that depends on all checks
          release = let
            releaseSystem = "x86_64-linux";
            pkgs = nixpkgs.legacyPackages.${releaseSystem};
          in pkgs.stdenv.mkDerivation {
            name = "laughing-potato-release";
            
            buildInputs = map (system: 
              allSystemJobs."check.${system}"
            ) supportedSystems;
            
            buildPhase = ''
              echo "Creating release for laughing-potato..."
              echo "All system checks have passed"
            '';
            
            installPhase = ''
              mkdir -p $out
              echo "Release ready" > $out/release-status.txt
              echo "Release created at: $(date)" >> $out/release-status.txt
              
              # Create release artifacts directory
              mkdir -p $out/artifacts
              echo "Release artifacts would be placed here" > $out/artifacts/README.txt
            '';
          };
        };
    };
}