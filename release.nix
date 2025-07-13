{ src, nixpkgs }:

let
  # Use the nixpkgs input directly - no <nixpkgs> reference
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  
  # Simple build job
  build = pkgs.stdenv.mkDerivation {
    name = "laughing-potato";
    src = src;
    
    buildPhase = ''
      echo "Building laughing-potato..."
      echo "Source contents:"
      ls -la
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      echo "#!/bin/bash" > $out/bin/laughing-potato
      echo "echo 'Hello from laughing-potato!'" >> $out/bin/laughing-potato
      chmod +x $out/bin/laughing-potato
    '';
  };

in
{
  # Simple job structure
  "build.x86_64-linux" = build;
  
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
      echo "Test passed" > $out/test-result.txt
    '';
  };
}