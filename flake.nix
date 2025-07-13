{
  description = "Simple Hydra setup with GitHub auto-discovery";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Your actual build jobs
        hydraJobs = {
          hello = pkgs.writeScriptBin "hello" ''
            #!${pkgs.bash}/bin/bash
            echo "Hello from laughing-potato!"
          '';
          
          test = pkgs.runCommand "test" {} ''
            echo "Running tests..."
            mkdir -p $out
            echo "Tests passed!" > $out/result
          '';
          
          build = pkgs.stdenv.mkDerivation {
            name = "laughing-potato";
            src = ./.;
            buildPhase = "echo 'Building...'";
            installPhase = ''
              mkdir -p $out/bin
              echo "#!/bin/bash" > $out/bin/laughing-potato
              echo "echo 'Hello from laughing-potato!'" >> $out/bin/laughing-potato
              chmod +x $out/bin/laughing-potato
            '';
          };
        };

        packages = self.hydraJobs.${system};
        defaultPackage = self.hydraJobs.${system}.hello;
      }
    ) // {
      # Hydra declarative jobsets using GitHub plugin
      jobsets = {
        # Main branch jobset
        main = {
          enabled = 1;
          hidden = false;
          description = "Main branch";
          nixexprinput = "src";
          nixexprpath = "flake.nix";
          checkinterval = 300;
          schedulingshares = 100;
          enableemail = false;
          keepnr = 10;
          inputs = {
            src = {
              type = "github";
              value = "shinedog laughing-potato main";
              emailresponsible = false;
            };
            nixpkgs = {
              type = "git";
              value = "https://github.com/NixOS/nixpkgs.git nixos-unstable";
              emailresponsible = false;
            };
          };
        };

        # GitHub plugin automatically discovers branches and PRs
        github-auto = {
          enabled = 1;
          hidden = false;
          description = "Auto-discovery for all branches and PRs";
          nixexprinput = "src";
          nixexprpath = "flake.nix";
          checkinterval = 300;
          schedulingshares = 50;
          enableemail = false;
          keepnr = 3;
          inputs = {
            src = {
              type = "github";
              value = "shinedog laughing-potato";
              emailresponsible = false;
            };
            nixpkgs = {
              type = "git";
              value = "https://github.com/NixOS/nixpkgs.git nixos-unstable";
              emailresponsible = false;
            };
          };
        };
      };
    };
}