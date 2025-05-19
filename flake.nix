{
  description = "Hydra fallback flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { nixpkgs, ... }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      hydraJobs = {
        mergeCheck = pkgs.runCommand "merge-check" {} ''
          echo ok > $out
        '';
      };
    };
}