{ nixpkgs, pulls, ... }:

let
  pkgs = import nixpkgs {};

  prs = let
  pullsFile = pulls or null;
  pullsContents = if pullsFile == null then "{}" else builtins.readFile pullsFile;
in builtins.fromJSON pullsContents;

  prJobsets =  pkgs.lib.mapAttrs (num: info:
    { enabled = 1;
      hidden = false;
      description = "PR ${num}: ${info.title}";
      checkinterval = 30;
      schedulingshares = 20;
      enableemail = false;
      emailoverride = "";
      keepnr = 1;
      type = 1;
      flake = "github:shinedog/laughing-potato/merge-requests/${info.iid}/head";
    }
  ) prs;
  mkFlakeJobset = branch: {
    description = "Build ${branch} branch of Laughing-Potato";
    checkinterval = "60";
    enabled = "1";
    schedulingshares = 100;
    enableemail = false;
    emailoverride = "";
    keepnr = 3;
    hidden = false;
    type = 1;
    flake = "github:shinedog/laughing-potato/${branch}";
  };

  desc = prJobsets // {
    "main" = mkFlakeJobset "main";
  };

  log = {
    pulls = prs;
    jobsets = desc;
  };

in {
  jobsets = pkgs.runCommand "spec-jobsets.json" {} ''
    cat >$out <<EOF
    ${builtins.toJSON desc}
    EOF
    # This is to get nice .jobsets build logs on Hydra
    cat >tmp <<EOF
    ${builtins.toJSON log}
    EOF
    ${pkgs.jq}/bin/jq . tmp
  '';
}
