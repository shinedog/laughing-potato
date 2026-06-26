{
  description = "Hydra jobset generator for shinedog/laughing-potato";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    hydraJobs.jobsets =
      pkgs.runCommand "laughing-potato-jobsets.json" {
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
        {
          git ls-remote --heads "$repoFetchUrl" \
            | awk '{ sub("refs/heads/", "", $2); print "branch\t" $2 "\t" $2 }'

          git ls-remote "$repoFetchUrl" 'refs/pull/*/head' \
            | awk '{ ref = $2; sub("^refs/pull/", "", ref); sub("/head$", "", ref); print "pull\t" ref "\t" $2 }'
        } | jq -Rn --arg flakeBaseUrl "$flakeBaseUrl" '
              def safeName:
                gsub("[^A-Za-z0-9_-]"; "-");

              def jobsetName:
                if .kind == "branch" and .name == "main" then
                  "main"
                elif .kind == "branch" then
                  "branch-" + (.name | safeName)
                else
                  "pull-" + (.name | safeName)
                end;

              def description:
                if .kind == "branch" then
                  "Build branch " + .name
                else
                  "Build pull request #" + .name
                end;

              [inputs
                | select(length > 0)
                | split("\t")
                | {kind: .[0], name: .[1], ref: .[2]}
              ] as $refs
              | reduce $refs[] as $ref ({};
                  .[$ref | jobsetName] = {
                    enabled: 3,
                    hidden: 0,
                    type: 1,
                    flake: ($flakeBaseUrl + "?ref=" + $ref.ref),
                    description: ($ref | description),
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
