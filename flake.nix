{
  description = "A Simple Flake for Testing a Hydra Installation and Jobset Configuration";
    inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { 
    self,
    nixpkgs
     }: {
    
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;

    hydraSpecs =
        let
          nfj = b: hydralib.flakeJob "github:shinedog/laughing-potato/${b}";
        in {
          jobsets = hydralib.makeSpec {
            nixcfg-main        = nfj "main";
            nixcfg-auto-update = nfj "auto-update";
          };
        };

      hydraJobs = genAttrs [ "aarch64-linux" "x86_64-linux" ] (system:
        {
          devshell = inputs.self.devShell.${system}.inputDerivation;
          selfPkgs = filterPkgs pkgs_.nixpkgs.${system} inputs.self.packages;
          hosts = (builtins.mapAttrs (n: v: v.config.system.build.toplevel)
            (filterHosts pkgs_.nixpkgs.${system} inputs.self.nixosConfigurations));
        });
    };
}
