{
  branches,
  nixpkgs,
  pulls,
  system ? "x86_64-linux",
}: let
  nixpkgsPath =
    if builtins.isAttrs nixpkgs
    then nixpkgs.outPath
    else nixpkgs;
  pkgs = import nixpkgsPath {inherit system;};
in {
  jobsets =
    pkgs.runCommand "laughing-potato-jobsets.json" {
      nativeBuildInputs = [pkgs.jq];

      branchesJson = branches.outPath;
      pullsJson = pulls.outPath;
      flakeBaseUrl = "git+ssh://git@github.com/shinedog/laughing-potato";
      preferLocalBuild = true;
      allowSubstitutes = false;
      meta.maintainers = ["nick@adriaanse.dev"];
    } ''
      jq -n \
        --slurpfile branches "$branchesJson" \
        --slurpfile pulls "$pullsJson" \
        --arg flakeBaseUrl "$flakeBaseUrl" '
          def safeName:
            gsub("[^A-Za-z0-9_-]"; "-");

          def branchJobsetName($name):
            if $name == "main" then
              "main"
            else
              "branch-" + ($name | safeName)
            end;

          def spec($description; $ref):
            {
              enabled: 3,
              hidden: 0,
              type: 1,
              flake: ($flakeBaseUrl + "?ref=" + $ref),
              description: $description,
              checkinterval: 60,
              schedulingshares: 100,
              enableemail: 0,
              emailoverride: "",
              keepnr: 3,
              inputs: {}
            };

          ($branches[0] // {}) as $branchRefs
          | ($pulls[0] // {}) as $pullRefs
          | reduce ($branchRefs | keys[]) as $branch ({};
              .[branchJobsetName($branch)] =
                spec("Build branch " + $branch; $branch)
            )
          | reduce ($pullRefs | keys[]) as $pull (.;
              .["pull-" + ($pull | safeName)] =
                spec("Build pull request #" + $pull; "refs/pull/" + $pull + "/head")
            )
        ' > "$out"
    '';
}
