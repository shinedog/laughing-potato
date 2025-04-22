{
  description = "Hydra PR merge-check runner";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Extract ref from Git metadata
      refPath = builtins.readFile ./.git/HEAD or "refs/heads/main"; # fallback for testing
      ref = builtins.elemAt (builtins.splitString "/" refPath) 2 or "main";
      prNumber = ref; # use "42" if ref = "pr/42"

      gitRemote = "git+https://github.com/shinedog/laughing-potato";

      mergeCheck = pkgs.runCommand "merge-check-${prNumber}" {
        nativeBuildInputs = [ pkgs.git pkgs.nix ];
      } ''
        set -euo pipefail

        mkdir work
        cd work
        git init
        git remote add origin ${gitRemote}
        git fetch origin main
        git checkout -b main FETCH_HEAD

        git fetch origin refs/pull/${prNumber}/head
        if ! git merge --no-commit --no-ff FETCH_HEAD; then
          echo "Merge conflict"
          exit 1
        fi

        nix build ${gitRemote}#nixosConfigurations.exampleHost.config.system.build.toplevel
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