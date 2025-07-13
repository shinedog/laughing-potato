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

          buildPhase = ''
            echo "Building laughing-potato..."
          '';

          installPhase = ''
            mkdir -p $out/bin
            echo "#!/bin/bash" > $out/bin/laughing-potato
            echo "echo 'Hello from laughing-potato!'" >> $out/bin/laughing-potato
            chmod +x $out/bin/laughing-potato
          '';

          meta = with pkgs.lib; {
            description = "Laughing Potato project";
            homepage = "https://github.com/shinedog/laughing-potato";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.unix;
          };
        };
      in {
        packages.default = laughing-potato;
        packages.laughing-potato = laughing-potato;

        formatter = pkgs.alejandra;

        # Simplified dev shell - remove system path references
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            alejandra
          ];

          shellHook = ''
            echo "Welcome to laughing-potato development environment!"
          '';
        };

        checks = {
          build = self.packages.${system}.default;
        };
      }
    )
    // {
      # Simplified hydraJobs - remove complex system references
      hydraJobs = 
        let
          supportedSystems = ["x86_64-linux"];
          
          mkSystemJobs = system: let
            pkgs = nixpkgs.legacyPackages.${system};
            package = self.packages.${system}.default;
            
            tests = pkgs.stdenv.mkDerivation {
              name = "laughing-potato-tests";
              src = ./.;
              
              buildPhase = ''
                echo "Running tests..."
                ${package}/bin/laughing-potato
              '';

              installPhase = ''
                mkdir -p $out
                echo "Tests completed" > $out/test-results.txt
              '';
            };
            
          in {
            "${system}" = package;
            "tests.${system}" = tests;
          };
          
          allSystemJobs = nixpkgs.lib.fold (system: acc: 
            acc // (mkSystemJobs system)
          ) {} supportedSystems;
          
        in allSystemJobs;
    };
}