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
      # Hydra-specific outputs that work across all systems
      hydraJobs = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"] (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};

          # Test job
          test = pkgs.stdenv.mkDerivation {
            name = "laughing-potato-tests";
            src = ./.;

            buildPhase = ''
              echo "Running tests for laughing-potato..."
              # Add test commands here
              # Example: make test
            '';

            installPhase = ''
              mkdir -p $out
              echo "Tests completed successfully" > $out/test-results.txt
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
              echo "Building documentation..."
              # Add doc build commands here
            '';

            installPhase = ''
              mkdir -p $out/share/doc
              # Copy documentation files
              echo "Documentation built" > $out/share/doc/README.txt
            '';
          };
        in {
          # Main package
          build = self.packages.${system}.default;
          inherit test docs;
        }
      );
    };
}
