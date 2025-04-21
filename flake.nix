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
    hydraJobs = {
      inherit (self)
        defaultPackage;
    };
    };
}
