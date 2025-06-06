{
  description = "Minimal test flake for Hydra";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    
    hydraJobs = {
      hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    };
  };
}