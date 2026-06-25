{
  description = "Hydra branch jobset generator for shinedog/laughing-potato";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    hydraJobs.jobsets = pkgs.runCommand "laughing-potato-branch-jobsets.json" {
      nativeBuildInputs = [
        pkgs.git
        pkgs.jq
        pkgs.openssh
      ];

      repoFetchUrl = "ssh://git@github.com/shinedog/laughing-potato.git";
      flakeBaseUrl = "git+ssh://git@github.com/shinedog/laughing-potato";
      preferLocalBuild = true;
      allowSubstitutes = false;
      meta.maintainers = ["nick@adriaanse.dev"];
    } ''
      git ls-remote --heads "$repoFetchUrl" \
        | awk '{ sub("refs/heads/", "", $2); print $2 }' \
        | jq -Rn --arg flakeBaseUrl "$flakeBaseUrl" '
            def jobsetName:
              if . == "main" then
                "main"
              else
                "branch-" + (gsub("[^A-Za-z0-9_-]"; "-"))
              end;

            [inputs | select(length > 0)] as $branches
            | reduce $branches[] as $branch ({};
                .[$branch | jobsetName] = {
                  enabled: 3,
                  hidden: 0,
                  type: 1,
                  flake: ($flakeBaseUrl + "?ref=" + $branch),
                  description: ("Build " + $branch),
                  checkinterval: 60,
                  schedulingshares: 100,
                  enableemail: 0,
                  emailoverride: "",
                  keepnr: 3,
                  inputs: {}
                }
              )
          ' > "$out"
    '';
  };
}
