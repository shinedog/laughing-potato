#!/usr/bin/env bash

# Script to discover branches and PRs for Hydra jobsets
# This can be called by Hydra to dynamically generate jobsets

REPO="shinedog/laughing-potato"
API_BASE="https://api.github.com/repos/$REPO"

# Get all branches
echo "Discovering branches..."
curl -s "$API_BASE/branches" | jq -r '.[].name' | while read branch; do
  echo "Found branch: $branch"
  # Output jobset configuration for this branch
  cat << EOF
{
  "branch-$branch": {
    "enabled": 1,
    "hidden": false,
    "description": "Build jobs for branch $branch",
    "flake": "git+https://github.com/$REPO.git?ref=$branch",
    "checkinterval": 300,
    "schedulingshares": 100,
    "enableemail": false,
    "emailoverride": "",
    "keepnr": 5
  }
}
EOF
done

# Get open PRs
echo "Discovering pull requests..."
curl -s "$API_BASE/pulls?state=open" | jq -r '.[] | "\(.number) \(.head.ref)"' | while read pr_num pr_ref; do
  echo "Found PR: #$pr_num ($pr_ref)"
  # Output jobset configuration for this PR
  cat << EOF
{
  "pr-$pr_num": {
    "enabled": 1,
    "hidden": false,
    "description": "Build jobs for PR #$pr_num",
    "flake": "git+https://github.com/$REPO.git?ref=$pr_ref",
    "checkinterval": 300,
    "schedulingshares": 50,
    "enableemail": false,
    "emailoverride": "",
    "keepnr": 3
  }
}
EOF