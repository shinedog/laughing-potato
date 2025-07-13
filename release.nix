# Fixed release.nix
{ src, nixpkgs ? <nixpkgs> }:

let
  # Import the flake and get its outputs
  flake = import "${src}/flake.nix";
  
  # Get nixpkgs
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  
  # Function to evaluate flake outputs
  evalFlake = flakeRef: let
    flakeOutputs = flake.outputs {
      self = flakeOutputs;
      nixpkgs = import nixpkgs { system = "x86_64-linux"; };
      flake-utils = import (fetchTarball "https://github.com/numtide/flake-utils/archive/master.tar.gz");
    };
  in flakeOutputs;
  
  # Get the flake outputs
  flakeOutputs = evalFlake src;
  
  # Extract hydra jobs - these should be the actual derivations
  hydraJobs = flakeOutputs.hydraJobs or {};
  
  # Function to create jobset for branch/PR discovery
  mkJobset = name: ref: {
    enabled = 1;
    hidden = false;
    description = "Build jobs for ${name}";
    flake = "git+https://github.com/shinedog/laughing-potato.git?ref=${ref}";
    checkinterval = 300;
    schedulingshares = 100;
    enableemail = false;
    emailoverride = "";
    keepnr = 5;
    inputs = {
      nixpkgs = {
        type = "git";
        value = "https://github.com/NixOS/nixpkgs.git nixos-25.05";
        emailresponsible = false;
      };
    };
  };

  # Dynamic branch discovery using GitHub API
  discoverBranches = pkgs.runCommand "discover-branches" {
    buildInputs = [ pkgs.curl pkgs.jq ];
  } ''
    # Get branches from GitHub API
    branches=$(curl -s "https://api.github.com/repos/shinedog/laughing-potato/branches" | jq -r '.[].name')
    
    # Get open PRs
    prs=$(curl -s "https://api.github.com/repos/shinedog/laughing-potato/pulls?state=open" | jq -r '.[] | "pr-\(.number)"')
    
    # Combine branches and PRs
    echo "$branches" > $out
    echo "$prs" >> $out
  '';

  # Read discovered branches (this is a simplified version - in practice you'd want more robust discovery)
  defaultBranches = [ "main" "develop" ];
  
  # Generate jobsets for discovered branches
  branchJobsets = builtins.listToAttrs (map (branch: {
    name = branch;
    value = mkJobset branch branch;
  }) defaultBranches);

in

# Return both the direct hydra jobs and the jobsets configuration
{
  # Direct jobs from flake
  jobs = hydraJobs;
  
  # Jobsets configuration for branch discovery
  jobsets = pkgs.writeText "jobsets.json" (builtins.toJSON branchJobsets);
  
  # Legacy support - expose jobs directly at top level
} // hydraJobs