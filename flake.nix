{
  description = "Hydra PR merge-check runner";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      ref = inputs.self.ref or "refs/heads/main";
      rev = inputs.self.rev or "main";

      # Detect PR number from ref
      maybePr = builtins.match "refs/remotes/origin/pr/([0-9]+)" ref;
      isPr = maybePr != null;
      prNumber = if isPr then builtins.elemAt maybePr 0 else null;

      gitRemote = "git+https://github.com/shinedog/laughing-potato";

      mergeCheck = pkgs.runCommand "merge-check-${rev}" {
        nativeBuildInputs = [ pkgs.git pkgs.nix ];
      } ''
        set -euo pipefail

        mkdir work
        cd work
        git init
        git remote add origin ${gitRemote}
        git fetch origin main
        git checkout -b main FETCH_HEAD

        ${if isPr then ''
          echo "Evaluating merged result of PR #${prNumber} into main..."
          git fetch origin refs/pull/${prNumber}/head
          if ! git merge --no-commit --no-ff FETCH_HEAD; then
            echo "Merge conflict in PR #${prNumber}"
            exit 1
          fi
        '' else ''
          echo "Not a PR ref (${ref}) — skipping merge step."
        ''}

        nix build ${gitRemote}#nixosConfigurations.exampleHost.config.system.build.toplevel
        echo "Success" > $out
      '';
    in {
      hydraJobs.mergeCheck = mergeCheck;
    };
}