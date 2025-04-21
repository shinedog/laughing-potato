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

rec {
  jobsetDefaults = {
    enabled = 1;
    hidden = false;
    keepnr = 3;
    schedulingshares = 100;
    checkinterval = 15;
    emailoverride = "";
    type = 1;
  };

  flakeJob = flakeRef: jobsetDefaults // {
    flake = flakeRef;
  };

  makeSpec = contents: builtins.derivation {
    name = "spec.json";
    system = "x86_64-linux";
    preferLocalBuild = true;
    allowSubstitutes = false;
    builder = "/bin/sh";
    args = [ (builtins.toFile "builder.sh" ''
      echo "$contents" > $out
    '') ];
    contents = builtins.toJSON contents;
  };
}

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
