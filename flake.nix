{
  description = "Hydra PR merge-check runner";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      ref = builtins.getEnv "HYDRA_REF";  # Hydra passes this via groupBy=ref
      prNumber = builtins.elemAt (builtins.split "/" ref) 1;

      mergeCheck = pkgs.runCommand "merge-check-${prNumber}" {
        nativeBuildInputs = [ pkgs.git pkgs.nix ];
      } ''
        set -euo pipefail

        mkdir work
        cd work
        git init
        git remote add origin ${self}
        git fetch origin main
        git checkout -b main FETCH_HEAD

        git fetch origin ${ref}
        if ! git merge --no-commit --no-ff FETCH_HEAD; then
          echo "Merge conflict"
          exit 1
        fi

        nix build ${self}#nixosConfigurations.exampleHost.config.system.build.toplevel
        echo "Success" > $out
      '';

      mergePR = pkgs.runCommand "merge-pr-${prNumber}" {
        nativeBuildInputs = [ pkgs.curl pkgs.jq ];
        GITHUB_TOKEN_FILE = /run/secrets/github-token;
        PR_NUMBER = prNumber;
        REPO = "shinedog/laughing-potato";
        inherit mergeCheck;
      } ''
        set -euo pipefail
        TOKEN=$(cat "$GITHUB_TOKEN_FILE")

        curl -s -X PUT \
          -H "Authorization: token $TOKEN" \
          -H "Accept: application/vnd.github+json" \
          "https://api.github.com/repos/$REPO/pulls/$PR_NUMBER/merge" \
          -d '{"merge_method":"squash"}' > $out
      '';
    in {
      hydraJobs.mergeCheck = mergeCheck;
      hydraJobs.mergePR = mergePR;
    };
}