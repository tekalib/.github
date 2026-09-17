#!/usr/bin/env bash
# Applies every ruleset in this directory to the organisation, matching on "name":
# existing ruleset -> updated in place, unknown name -> created.
# Needs: gh authenticated with admin:org, and GitHub Team (org rulesets 403 on Free).
set -euo pipefail

ORG="${1:-tekalib}"
cd "$(dirname "$0")"

existing=$(gh api "orgs/$ORG/rulesets" --paginate --jq '.[] | "\(.id) \(.name)"')

for file in *.json; do
  name=$(jq -r .name "$file")
  id=$(printf '%s\n' "$existing" | awk -v n="$name" '{ id = $1; $1 = ""; sub(/^ /, ""); if ($0 == n) print id }')

  if [ -n "$id" ]; then
    gh api -X PUT "orgs/$ORG/rulesets/$id" --input "$file" --jq '"updated  \(.name)"'
  else
    gh api -X POST "orgs/$ORG/rulesets" --input "$file" --jq '"created  \(.name)"'
  fi
done
