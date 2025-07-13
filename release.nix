{ src, nixpkgs ? <nixpkgs> }:

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  
  # Import the flake from the source
  flake = import "${src}/flake.nix";
  
  # Evaluate the flake
  flakeInputs = {
    nixpkgs = import nixpkgs { system = "x86_64-linux"; };
    flake-utils = import (fetchTarball "https://github.com/numtide/flake-utils/archive/master.tar.gz");
  };
  
  flakeOutputs = flake.outputs (flakeInputs // { self = flakeOutputs; });
  
  # Get hydra jobs
  hydraJobs = flakeOutputs.hydraJobs or {};
  
  # Function to create jobset configuration
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
  };

  # Define jobsets using main branch (not master)
  jobsetsConfig = {
    "main" = mkJobset "main branch" "main";
    "develop" = mkJobset "develop branch" "develop";
    # Add more branches as needed
  };

in
{
  # Export the hydra jobs directly
  jobs = hydraJobs;
  
  # Export jobsets configuration
  jobsets = pkgs.writeText "jobsets.json" (builtins.toJSON jobsetsConfig);
  
  # Also export jobs at top level for direct access
} // hydraJobs