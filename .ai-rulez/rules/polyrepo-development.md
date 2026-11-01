---
type: Decision
title: Polyrepo Development
x-ai-rulez:
  kind: rule
  id: polyrepo-development
  metadata:
    priority: critical
---

- This root tracks only orchestration files (`mise.toml`, `mise-tasks/`, `repos.txt`, `toolchains.toml`, `.ai-rulez/`, `.github/`, `poly.toml`; `git ls-files` lists all). Each registry directory is its own git repository: run git, tasks and commits inside it, never stage its files from the root.
- `repos.txt` is the full set of managed repositories. Do not clone, copy or create other top-level directories; add a repository to it and run `mise run setup:clone`. Local scratch goes in `reports/` (ignored); never a sibling checkout or worktree.
- Work on a branch in `.worktrees/<repo>/<branch>`, created with `mise run worktree:add <repo> <branch>`; one worktree per agent, so parallel agents never share a checkout. `mise run worktree:remove <repo> <branch>` removes it once the branch is merged (layout: the `polyrepo-structure` context).
- Before changing a repository, read its own `AGENTS.md`/`CLAUDE.md` and run its tasks (`mise -C <repo> tasks`); its conventions override this root's.
- Bring repositories up to date with `mise run repos:pull`; it only fast-forwards, and reports diverged or blocked repositories for a human to reconcile.
- Regenerate governance with `mise run setup:ai-rulez`, install hooks with `mise run setup:hooks`. Repositories include `xberg-io/agent-conventions` by version range and pin tools to an `xberg-io/toolchains` baseline in `toolchains.toml`; `mise run ai-rulez:update` moves every agent-conventions pin to the newest allowed release.
- `agent-conventions` and `toolchains` belong to the xberg-io organization and are not in this workspace: change a shared rule or tool version there (from the xberg-io polyrepo), tag a release, then update here. Fix ai-rulez and Poly defects in the `ai-rulez/` and `poly/` repositories with a regression test rather than patching generated output.
