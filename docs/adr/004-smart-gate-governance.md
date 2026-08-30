# ADR-004: Smart Gate CI logic and the self-modifying workflow attack

## Status

Accepted

## Context

`foundation-validation.yml` originally ran the same full set of checks
(schema validation, OpenAPI lint, naming conventions, ADR format) on
every push and every pull request, regardless of which files actually
changed. This was correct but wasteful: a PR that only touched
`README.md` still paid the cost of a full validation run.

P0-6 introduced a **Smart Gate**: a path-filter job (`changes`, using
`dorny/paths-filter@v3`) that determines whether a PR/push touches a
fixed governed scope:

```
schemas/**
policies/**
templates/**
.spectral.yaml
scripts/**
.github/workflows/**
docs/adr/**
```

Two downstream jobs consume that decision:

- **Hard Gate** — cheap repo-hygiene checks (required files, GitHub
  config). Runs unconditionally, with no dependency on `changes`, so a
  broken/blocked filter step can never silently skip it.
- **Full Validation** — the expensive schema/spec/script/ADR checks.
  Runs only when the governed scope was touched, or on any `push`
  event (already-merged code gets full validation regardless, as
  defense-in-depth).

## Decision

Implement the Smart Gate as described above, and validate it against
three scenarios before trusting it:

1. **Positive** — a PR touching only `README.md`.
2. **Negative (mixed)** — a PR touching `README.md` *and* a governed
   path (`schemas/canonical/entity.schema.json`) in the same commit.
3. **Negative (self-modifying attack)** — a PR that edits
   `foundation-validation.yml` itself, attempting to remove
   `.github/workflows/**` from the governed-scope list.

### Results

| Case | Expected | Actual (first run) |
|---|---|---|
| Positive | Hard Gate success, Full Validation skipped | ✅ Matched |
| Negative (mixed) | Entire PR treated as governed, Full Validation runs | ✅ Matched |
| Negative (self-modifying attack) | Full Validation still runs / PR blocked | ❌ **Full Validation was skipped** |

### Root cause of the self-modifying attack gap

For the `pull_request` trigger, GitHub Actions loads the workflow
file's *definition* — including the Smart Gate's own path-filter list
— from the **PR's head branch**, not from the base branch. A PR that
edits `foundation-validation.yml` to remove
`.github/workflows/**` from the governed list is evaluated using that
*new* list. Since the only file the PR touches is
`.github/workflows/foundation-validation.yml`, and that path is no
longer in the (attacker-edited) governed list, `changes` reports
`governed=false` and Full Validation is skipped — in the same commit
that weakened the rule.

This is a structural property of `pull_request`, not a bug in the
Smart Gate's YAML logic. No amount of `if:` conditions inside that
same workflow file can close it, because the attacker's edit takes
effect before those conditions are ever evaluated.

## Remediation

Two complementary controls were added. Neither depends on the
Smart Gate's own file content being trustworthy.

### 1. `Governance Guard` workflow (`.github/workflows/governance-guard.yml`)

Triggered on `pull_request_target`, which GitHub always evaluates
using the workflow file version **from the base branch**, regardless
of what the PR changes. The job:

- Never checks out PR code and never uses secrets — it only reads PR
  metadata (changed files) and check-run results via the read-only
  GitHub API, which is what makes `pull_request_target` safe to use
  here.
- Independently re-derives whether the PR touches governed scope
  (its own copy of the same path list, but one the PR cannot edit
  away, since this file is read from `main`).
- If governed, polls the Checks API for the `Full Validation
  (governed scope)` check on the PR's head SHA and fails unless that
  check concluded with `success`.

Retested against the same self-modifying attack after merging this
workflow to `main`: the new `Governance Guard / Verify Full
Validation Ran For Governed Changes` check correctly failed, flagging
the PR as unsafe to merge (PR #12, closed without merging).

### 2. CODEOWNERS (`.github/CODEOWNERS`)

All seven governed paths are assigned to the repository's maintainer,
forcing changes to go through a PR rather than a direct push.

**Known limitation (solo maintainer):** GitHub does not allow a PR
author to satisfy a "require review from Code Owners" branch
protection rule by approving their own PR. With a single
collaborator, that rule is intentionally **not** enabled — see the
note in `CODEOWNERS` itself. Branch protection instead relies on:

- Required status checks: `Hard Gate`, `Full Validation (governed
  scope)`, `Governance Guard / Verify Full Validation Ran For
  Governed Changes`.
- Restrict who can push to `main` (limited to the maintainer).

If a second collaborator is added in the future, enabling
"require review from Code Owners" should be revisited — it would
close the remaining gap where the maintainer can still merge their
own governed-scope PR without independent review.

## Consequences

- Ordinary PRs (docs, non-governed code) get faster CI feedback,
  since Full Validation is skipped when it isn't needed.
- Governed-scope PRs, including ones that edit the Smart Gate itself,
  cannot silently bypass full validation — Governance Guard catches
  it independently of the edited file.
- The workflow-definition-loaded-from-head behavior of `pull_request`
  is now a documented, known property of the pipeline rather than an
  unnoticed gap. Any future workflow file added to this repo that
  gates on its own path list should be reviewed against this same
  failure mode.
- Solo-maintainer operation means CODEOWNERS enforces PR-based change
  control but not independent review. This is an accepted, documented
  trade-off, not an oversight.

## Test artifacts

- PR #7 — Positive case
- PR #8 — Negative (mixed) case
- PR #9 — Negative (self-modifying attack), first run — found the gap
- PR #10 — CODEOWNERS fix (fictional teams → real account)
- PR #11 — Governance Guard added
- PR #12 — Negative (self-modifying attack), retest post-remediation — confirmed the fix
- PR #15 — Negative (self-modifying attack), retest on new org/public
  repo after migrating off personal private repo (branch protection
  enforcement requires public repo or paid tier on personal accounts).
  Same result as PR #12: Smart Gate bypassed as expected, Governance
  Guard caught it, merge button disabled. Confirms remediation holds
  after the repo migration.
All test PRs were closed without merging; only PR #10 and PR #11 were
merged to `main`.
