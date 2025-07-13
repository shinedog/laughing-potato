# Minimal release.nix for testing - replace your current one with this if the above still fails
{ src, nixpkgs ? <nixpkgs> }:

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  
  # Super simple build job
  build = pkgs.stdenv.mkDerivation {
    name = "laughing-potato";
    src = src;
    
    buildPhase = ''
      echo "Building laughing-potato from source..."
      echo "Contents of source directory:"
      find . -name "*.nix" -o -name "*.md" -o -name "*.json" | head -20
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      echo "#!/bin/bash" > $out/bin/laughing-potato
      echo "echo 'Hello from laughing-potato built by Hydra!'" >> $out/bin/laughing-potato
      chmod +x $out/bin/laughing-potato
      
      # Also create a version file
      echo "dev-$(date +%Y%m%d)" > $out/version.txt
    '';
  };

in
{
  # Simple job structure that Hydra can definitely handle
  "build.x86_64-linux" = build;
  
  # Add a test job
  "test.x86_64-linux" = pkgs.stdenv.mkDerivation {
    name = "laughing-potato-test";
    src = src;
    buildInputs = [ build ];
    
    buildPhase = ''
      echo "Testing laughing-potato..."
      ${build}/bin/laughing-potato
    '';
    
    installPhase = ''
      mkdir -p $out
      echo "Test passed at $(date)" > $out/test-result.txt
    '';
  };
}