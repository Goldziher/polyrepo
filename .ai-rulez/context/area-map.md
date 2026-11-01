---
type: Concept
title: Area Map
x-ai-rulez:
  kind: context
  id: area-map
  metadata:
    priority: high
---

# Area Map

- `repos.txt` — the repos this workspace clones, one `<dir> <remote>` per line; all are under `github.com/Goldziher`
- `mise.toml` — settings only, no `[tools]` (inherited by every subrepo); `mise-tasks/` — root-only tasks that pin their own tools: `setup:*`,
  `repos:*` (`status`, `pull`), `worktree:*`, `ai-rulez:*` (`check`, `update`), `governance:*`, `lint`/`format`; product
  development tasks live in each repository
- `toolchains.toml` — the `xberg-io/toolchains` baseline the root task pins follow
- `.ai-rulez/` — governance for this root only; shared modules come from `xberg-io/agent-conventions`
- `poly.toml` — root lint, format and hook config; subrepos are excluded from discovery
- `.github/workflows/` — CI for this repo's governance sources
- `.worktrees/<repo>/<name>` — every git worktree (gitignored); layout and naming: the `polyrepo-structure` context

Repositories by area:

- Lint, format and repo hygiene: `poly`, `uncomment`, `gitfluff`, `adrlint`, `skif`, `scythe`, `gh-actions-updater`, `voom`
- Agent tooling: `ai-rulez`, `basemind`, `prompt-template`
- Libraries and frameworks: `spikard`, `wirx`, `interface-forge`, `fabricator`, `go-utils`, `monomyth`
- Services, ML and private projects: `starmetal`, `ocr-training`, `magius`
- Distribution and profile: `homebrew-tap`, `scoop-bucket`, `profile` (the `Goldziher/Goldziher` profile README)
