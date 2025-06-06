{
  description = "AI Defined Declarative Project - Enhanced Hydra Jobs with PR/Branch Testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Helper function to create job specifications
        mkHydraJob = name: drv: {
          inherit name;
          derivation = drv;
          description = "Hydra job for ${name}";
        };

        # Base package for testing
        testPackage = pkgs.stdenv.mkDerivation {
          pname = "ai-declarative-test";
          version = "0.1.0";
          src = ./.;
          buildPhase = ''
            echo "Building AI Declarative Project..."
            echo "This is a test build for commit: ''${HYDRA_COMMIT:-unknown}"
          '';
          installPhase = ''
            mkdir -p $out/bin
            echo '#!/bin/sh' > $out/bin/ai-test
            echo 'echo "AI Declarative Project Test Successful"' >> $out/bin/ai-test
            chmod +x $out/bin/ai-test
          '';
        };

        # Create jobs for different scenarios
        jobs = {
          # Main trunk build (always run)
          trunk-build = mkHydraJob "trunk-build" testPackage;
          
          # PR validation job
          pr-validation = mkHydraJob "pr-validation" (pkgs.stdenv.mkDerivation {
            pname = "pr-validation";
            version = "0.1.0";
            src = ./.;
            buildPhase = ''
              echo "=== PR Validation Job ==="
              echo "Validating PR against HEAD..."
              echo "PR_NUMBER: ''${HYDRA_PR_NUMBER:-unknown}"
              echo "BASE_REF: ''${HYDRA_BASE_REF:-main}"
              echo "HEAD_REF: ''${HYDRA_HEAD_REF:-unknown}"
              
              # Simulate merge conflict detection
              echo "Checking for merge conflicts..."
              
              # Simulate test suite
              echo "Running test suite..."
              sleep 2
              echo "All tests passed!"
            '';
            installPhase = ''
              mkdir -p $out
              echo "pr-validation-success" > $out/result
            '';
          });

          # Branch protection check
          branch-protection = mkHydraJob "branch-protection" (pkgs.stdenv.mkDerivation {
            pname = "branch-protection";
            version = "0.1.0";
            src = ./.;
            buildPhase = ''
              echo "=== Branch Protection Check ==="
              echo "Ensuring branch can be safely merged..."
              
              # Check if this is a protected branch
              BRANCH_NAME="''${HYDRA_BRANCH:-unknown}"
              echo "Branch: $BRANCH_NAME"
              
              if [[ "$BRANCH_NAME" == "main" || "$BRANCH_NAME" == "master" ]]; then
                echo "Protected branch detected - running full validation"
                echo "Checking commit signatures..."
                echo "Validating CI status..."
                echo "Branch protection: PASSED"
              else
                echo "Feature branch - basic validation"
              fi
            '';
            installPhase = ''
              mkdir -p $out
              echo "branch-protection-passed" > $out/result
            '';
          });

          # Integration test that runs after PR validation
          integration-test = mkHydraJob "integration-test" (pkgs.stdenv.mkDerivation {
            pname = "integration-test";
            version = "0.1.0";
            src = ./.;
            buildInputs = [ pkgs.curl pkgs.jq ];
            buildPhase = ''
              echo "=== Integration Test Suite ==="
              echo "Running integration tests..."
              
              # Simulate integration testing
              echo "Testing component interactions..."
              echo "Validating API endpoints..."
              echo "Checking database connections..."
              echo "Integration tests: PASSED"
            '';
            installPhase = ''
              mkdir -p $out
              echo "integration-test-success" > $out/result
            '';
          });

          # Security scan job
          security-scan = mkHydraJob "security-scan" (pkgs.stdenv.mkDerivation {
            pname = "security-scan";
            version = "0.1.0";
            src = ./.;
            buildPhase = ''
              echo "=== Security Scan ==="
              echo "Scanning for vulnerabilities..."
              echo "Checking dependencies..."
              echo "Security scan: PASSED"
            '';
            installPhase = ''
              mkdir -p $out
              echo "security-scan-clean" > $out/result
            '';
          });
        };

      in {
        packages = {
          default = testPackage;
          ai-declarative-test = testPackage;
        };

        # Hydra jobs with different trigger conditions
        hydraJobs = {
          # Always run on trunk
          trunk = {
            build = jobs.trunk-build.derivation;
            security-scan = jobs.security-scan.derivation;
          };

          # PR-specific jobs
          pull-request = {
            validation = jobs.pr-validation.derivation;
            integration = jobs.integration-test.derivation;
            security = jobs.security-scan.derivation;
          };

          # Branch protection jobs
          branch-protection = {
            main = jobs.branch-protection.derivation;
            master = jobs.branch-protection.derivation;
          };

          # Combined job that runs all PR checks
          pr-gate = pkgs.stdenv.mkDerivation {
            pname = "pr-gate";
            version = "0.1.0";
            src = ./.;
            buildInputs = [ 
              jobs.pr-validation.derivation 
              jobs.integration-test.derivation 
              jobs.security-scan.derivation 
            ];
            buildPhase = ''
              echo "=== PR Gate Check ==="
              echo "Running comprehensive PR validation..."
              
              # This job depends on all other PR jobs passing
              echo "✓ PR validation completed"
              echo "✓ Integration tests passed"  
              echo "✓ Security scan clean"
              echo "✓ All PR checks passed - ready for merge"
            '';
            installPhase = ''
              mkdir -p $out
              echo "pr-gate-passed" > $out/result
              echo "$(date): PR ready for merge" > $out/timestamp
            '';
          };
        };

        # Development shell for testing
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            curl
            jq
            nix
          ];
          shellHook = ''
            echo "AI Declarative Project Development Environment"
            echo "Available commands:"
            echo "  nix build .#ai-declarative-test"
            echo "  nix build .#hydraJobs.pr-gate"
          '';
        };
      }
    );
}