{ src }:

let
  # Use the flake's own nixpkgs instead of requiring it as input
  flake = builtins.getFlake "path:${src}";
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  
  # Function to create a jobset configuration
  mkJobset = name: flakeRef: {
    enabled = 1;
    hidden = false;
    description = "Build jobs for ${name}";
    flake = flakeRef;
    checkinterval = 300;
    schedulingshares = 100;
    enableemail = false;
    emailoverride = "";
    keepnr = 5;
  };

  # Define the jobsets you want to create
  jobsetsConfig = {
    "main" = mkJobset "main branch" "git+https://github.com/shinedog/laughing-potato.git?ref=main";
    "develop" = mkJobset "develop branch" "git+https://github.com/shinedog/laughing-potato.git?ref=develop";
    # Add more branches as needed
  };

in

{
  jobsets = pkgs.writeText "jobsets.json" (builtins.toJSON jobsetsConfig);
}