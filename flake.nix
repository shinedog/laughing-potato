{
  description = "Fallback Hydra flake for merge-check";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mergeCheck = pkgs.runCommand "merge-check-fallback" {
        nativeBuildInputs = [ pkgs.coreutils ];
      } ''
        echo "Hydra fallback job executed successfully." > $out
      '';
    in {
      hydraJobs = {
        mergeCheck = mergeCheck;
      };
    };
}