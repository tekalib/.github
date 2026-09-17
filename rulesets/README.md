# Organisation rulesets

Branch policy for every `tekalib` repository, as code. Source of truth: these files.
Edit a file, run `./apply.sh`, never edit a ruleset in the GitHub UI, the next apply would
overwrite it.

```sh
gh auth refresh -h github.com -s admin:org   # once
./apply.sh                                   # or ./apply.sh <other-org>
```

**Requires GitHub Team.** On Free, these endpoints return `403 Upgrade to GitHub Team`
and neither rulesets nor classic branch protection apply to private repositories at all,
so a downgrade silently unprotects every repository but `.github`.

| Ruleset                     | Targets                                | Enforces                                            | Admin bypass |
| --------------------------- | -------------------------------------- | --------------------------------------------------- | ------------ |
| Conventional Branch Naming  | all repos, all branches                | branch creation limited to the allowed prefixes      | no           |
| Trunk Protection            | all repos, default branch + `develop`  | no deletion, no force-push                           | no           |
| Trunk Merge Flow            | all repos, default branch + `develop`  | pull request, squash only, threads resolved, signed  | yes          |

Required CI checks are deliberately absent: they differ per repository and each project
already gates its own merges in `ci.yml`. This repository is public, so nothing here may
name a private repository anyway.

## Why it is shaped this way

- **Prefixes, not patterns.** [Conventional Branch](https://conventionalbranch.org) wants
  `<type>/<lowercase-kebab-description>`. Rulesets can express that as a regex
  (`branch_name_pattern`), but that rule is silently ignored outside GitHub Enterprise:
  tested on 2026-09-17 with the rule active and bypass set to `never`, creating `Bad_Branch`
  still succeeded. So the naming ruleset inverts the logic instead, it restricts creation
  everywhere and excludes the allowed prefixes. Consequence: the prefix is enforced by
  GitHub, the description format is not.
- **Machine branches are excluded, not bypassed.** `dependabot/**` and GitHub's own
  `revert-<pr>-<branch>` are in the exclusion list, so no bot needs bypass rights.
- **No bypass on Trunk Protection.** Deleting or force-pushing a trunk is never part of a
  workflow, so nobody gets to.
- **Bypass on the merge flow.** `back-merge.yml` pushes `main` into `develop` directly with
  `AUTOMATION_TOKEN`, an organisation admin's PAT. Blocking it would mean rewriting that
  workflow around a pull request. Cost of the bypass: an admin can also push to a trunk by
  hand, discipline is the only guard there.
- **Zero required approvals.** A solo maintainer cannot approve their own pull request.
  Raise the count on the day a second maintainer joins.
- **Signatures sit in the bypassed ruleset.** `back-merge.yml` merges from a runner with no
  signing key, so a non-bypassable signature rule would break the pipeline. Here it holds for
  everyone who is not an organisation admin.
- **Replaced "Default Branch Security"** (UI-only, deleted 2026-09-17). It duplicated the
  three rules above more loosely, and its `required_linear_history` was redundant with
  squash-only merges, its `copilot_code_review` inert with zero Copilot seats.
