{
  description = "Safe fallback Hydra flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Always return a dummy job to avoid evaluation crash
      mergeCheck = pkgs.runCommand "merge-check-fallback" {
        nativeBuildInputs = [ pkgs.coreutils ];
      } ''
        echo "No-op check for fallback" > $out
      '';
    in {
      hydraJobs = {
        mergeCheck = mergeCheck;
      };
    };
}