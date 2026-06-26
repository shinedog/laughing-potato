# Hydra configuration

The root `jobsets.json` bootstraps the `.jobsets` jobset and points Hydra at
`jobsets.nix` in this directory. Keep the root file while Hydra's project edit
path cannot update an existing flake `.jobsets` row without violating its
database constraints.

The expression generates one jobset for each branch and pull request returned by
Hydra's GitHub input plugins:

- `github_refs` for branch refs
- `githubpulls` for open pull requests

Those plugins fetch JSON through the GitHub API during input fetching, so the
generator build only transforms store-path JSON files and does not need network
or SSH credentials inside the Nix build sandbox.
