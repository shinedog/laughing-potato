# Release.nix - Improved version with better error handling
{ src, nixpkgs }:

let
  # Use the nixpkgs input directly - no <nixpkgs> reference
  pkgs = import nixpkgs { 
    system = "x86_64-linux"; 
    # Add config to ensure no unfree packages cause issues
    config = { 
      allowUnfree = false; 
      allowBroken = false; 
    }; 
  };
  
  # Simple build job with better error handling
  build = pkgs.stdenv.mkDerivation {
    name = "laughing-potato";
    src = src;
    
    # Explicitly set phases to avoid any default behavior issues
    phases = [ "unpackPhase" "buildPhase" "installPhase" ];
    
    buildPhase = ''
      echo "Building laughing-potato..."
      echo "Source contents:"
      ls -la
      echo "Current directory: $(pwd)"
      echo "Environment variables:"
      env | grep -E "(PATH|HOME|TMP)" || true
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      echo "#!/bin/bash" > $out/bin/laughing-potato
      echo "echo 'Hello from laughing-potato!'" >> $out/bin/laughing-potato
      chmod +x $out/bin/laughing-potato
      
      # Verify the binary was created
      ls -la $out/bin/
    '';
    
    # Add metadata to help with debugging
    meta = with pkgs.lib; {
      description = "Laughing Potato project";
      platforms = platforms.linux;
    };
  };

  # Test job with better isolation
  test = pkgs.stdenv.mkDerivation {
    name = "laughing-potato-test";
    src = src;
    
    # Explicitly depend on the build
    buildInputs = [ build ];
    phases = [ "unpackPhase" "buildPhase" "installPhase" ];
    
    buildPhase = ''
      echo "Testing laughing-potato..."
      echo "Build output location: ${build}"
      echo "Available binaries:"
      ls -la ${build}/bin/ || echo "No binaries found"
      
      # Run the test
      if [ -x "${build}/bin/laughing-potato" ]; then
        echo "Running binary:"
        ${build}/bin/laughing-potato
        echo "Test completed successfully"
      else
        echo "ERROR: Binary not found or not executable"
        exit 1
      fi
    '';
    
    installPhase = ''
      mkdir -p $out
      echo "Test passed at $(date)" > $out/test-result.txt
      echo "Build hash: ${build}" >> $out/test-result.txt
    '';
  };

in
{
  # Simple job structure - avoid complex attribute names
  build = build;
  test = test;
  
  # Also provide the old format for compatibility
  "build.x86_64-linux" = build;
  "test.x86_64-linux" = test;
}