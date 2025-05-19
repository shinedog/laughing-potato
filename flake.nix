{
  description = "Safe static Hydra flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { nixpkgs, ... }: {
    hydraJobs = {
      mergeCheck = nixpkgs.legacyPackages.x86_64-linux.runCommand "merge-check" {} ''
        echo "Static merge check passed." > $out
      '';
    };
  };
}