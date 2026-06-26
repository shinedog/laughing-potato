# Hydra configuration

`jobsets.json` bootstraps the `.jobsets` jobset and points Hydra at the flake in
this directory. The flake generates one jobset for each branch and pull request
ref returned by `git ls-remote`.

This uses Git over SSH because the Hydra builder currently has repository SSH
access. If that stops being true, switch the generator to use Hydra's GitHub
input plugins instead:

- `github_refs` for branch or tag refs
- `githubpulls` for open pull requests

Those plugins fetch JSON through the GitHub API, so the generator would consume
the plugin-provided input files instead of running `git ls-remote`.
