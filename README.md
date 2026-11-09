# goldziher

Polyrepo workspace for the projects under the [Goldziher](https://github.com/Goldziher) GitHub namespace. This repo
tracks only workspace orchestration: the repository registry, root AI governance, setup tasks and lint config. Every
subdirectory below is an independent git repository, cloned by `mise run setup:clone` and ignored here.

The point is one checkout to launch coding agents from: each agent starts at this root, reads the workspace
conventions, and works in its own worktree of whichever repository the task is about.

The layout and tasks mirror the [xberg-io polyrepo](https://github.com/xberg-io/polyrepo). The repositories here
share that organization's tooling: tool versions follow an [xberg-io/toolchains](https://github.com/xberg-io/toolchains)
baseline, and AI governance includes [xberg-io/agent-conventions](https://github.com/xberg-io/agent-conventions).
Both stay in the xberg-io organization and are not cloned here.

## Repositories

[`repos.txt`](repos.txt) is the source of truth: every non-archived code repository under `Goldziher` that is not a fork,
except this one; private personal repositories (`taxes`, `apartment-search`, `devscout`) stay out. Each is cloned into a directory
of the same name, except `Goldziher/Goldziher` (the profile README), cloned as `profile/`.

### Lint, format and repository hygiene

| Repository | Description |
|------------|-------------|
| [polylint](https://github.com/Goldziher/polylint) | Universal polyglot linter and formatter (the `poly` command): one binary and one `poly.toml` for every language, engines downloaded on demand, git hooks and an MCP server |
| [uncomment](https://github.com/Goldziher/uncomment) | Fast CLI that removes comments from code using tree-sitter grammars |
| [gitfluff](https://github.com/Goldziher/gitfluff) | Conventional Commits linter with automatic message cleanup |
| [adrlint](https://github.com/Goldziher/adrlint) | Rust linter and formatter for MADR architecture decision records |
| [skif](https://github.com/Goldziher/skif) | Opinionated, zero-config linter for TypeScript and JavaScript monorepos |
| [scythe](https://github.com/Goldziher/scythe) | SQL formatting, linting, security auditing and type-safe code generation for 10 languages |
| [gh-actions-updater](https://github.com/Goldziher/gh-actions-updater) | CLI and pre-commit hook that updates GitHub Action versions |
| [voom](https://github.com/Goldziher/voom) | Fast, parallel polyglot build-artifact and cache pruning |

### Agent tooling

| Repository | Description |
|------------|-------------|
| [ai-rulez](https://github.com/Goldziher/ai-rulez) | Author, generate, validate and govern AI agent rules, skills, plugins and MCP configuration |
| [basemind](https://github.com/Goldziher/basemind) | AI context and content layer for coding agents over one MCP server |
| [prompt-template](https://github.com/Goldziher/prompt-template) | Lightweight library for prompt templates |

### Libraries and frameworks

| Repository | Description |
|------------|-------------|
| [spikard](https://github.com/Goldziher/spikard) | Codegen-first polyglot web toolkit: one Rust core, 14 language bindings |
| [wirx](https://github.com/Goldziher/wirx) | Private: polyglot serialization, deserialization and validation on a Rust core |
| [interface-forge](https://github.com/Goldziher/interface-forge) | Mock-data generation for TypeScript |
| [fabricator](https://github.com/Goldziher/fabricator) | Typed test data factories for Go |
| [go-utils](https://github.com/Goldziher/go-utils) | Go generics utilities inspired by JavaScript and Python |
| [monomyth](https://github.com/Goldziher/monomyth) | Experimental engine for narrative structure generation |

### Services, ML and private projects

| Repository | Description |
|------------|-------------|
| [starmetal](https://github.com/Goldziher/starmetal) | Self-hosted multi-language package registry and registry proxy |
| [ocr-training](https://github.com/Goldziher/ocr-training) | Private: LSTM model training and optimization for Tesseract OCR |

### Distribution and profile

| Repository | Description |
|------------|-------------|
| [homebrew-tap](https://github.com/Goldziher/homebrew-tap) | Homebrew formulae |
| [scoop-bucket](https://github.com/Goldziher/scoop-bucket) | Scoop manifests (Windows) |
| [Goldziher](https://github.com/Goldziher/Goldziher) | GitHub profile README (`profile/`) |

To add a repository, append `<dir> <remote>` to `repos.txt`, add `<dir>/**` to `[discovery] exclude` in
`poly.toml`, list it above and in `.ai-rulez/context/area-map.md`, then run `mise run setup:clone`.

## Setup

Prerequisites:

- [mise](https://mise.jdx.dev). Each task in `mise-tasks/` pins the tools it runs with (Node, Python,
  [polylint](https://github.com/Goldziher/polylint), shfmt, ShellCheck, jq) at the toolchains baseline named in
  `toolchains.toml`, and mise installs them on first use. `mise.toml` has no `[tools]`, because every subrepository
  inherits it, and the root `mise.lock` is gitignored: every subrepository install rewrites a parent lockfile to its
  own platforms.
- SSH access to `github.com/Goldziher`; the private repositories need it.
- `ai-rulez` on `PATH` for the git hooks: `npm install -g ai-rulez@latest` (Node 22 or later). The tasks themselves
  always run ai-rulez at npm latest through `npx -y ai-rulez@latest`.

```sh
git clone git@github.com:Goldziher/polyrepo.git goldziher
cd goldziher
mise trust
mise run setup
```

`mise run setup` runs four steps, in order, and runs every step even when an earlier one fails, so a single
inaccessible repository or broken subrepository setup never leaves the rest of the workspace unprovisioned. It exits
non-zero and names the failed steps at the end; each step reports the repositories it failed in.

1. `setup:clone` clones every repository in `repos.txt` that is not checked out yet.
2. `setup:hooks` installs Poly git hooks in the root and in every repository whose `poly.toml` declares `[hooks]`.
   Poly reads `[hook_preferences]` only from the repository it installs into, so for each repository with external
   hook sources the task records `channels = ["system"]` in that repository's gitignored `poly.local.toml` first. It
   refuses to write one that the repository does not gitignore.
3. `setup:subrepos` runs `mise run setup` in each repository that defines its own `setup` task.
4. `setup:ai-rulez` runs `npx -y ai-rulez@latest generate --no-local --gitignore` in the root, then
   `generate --recursive --no-local --gitignore` inside each repository with an `.ai-rulez/config.toml`. It skips
   `plugin/` (built by each product's plugin pipeline) and ai-rulez's `tests/fixtures/` and
   `internal/migrate/testdata/` (test configs a plain generate would rewrite). `--gitignore` keeps each repository's
   managed `.gitignore` block in step with its Claude, Codex and OpenCode outputs.

Rerun any step on its own; every one is idempotent. Afterwards, `mise run ai-rulez:check` and `mise run repos:status`
confirm the result.

## Tasks

Tasks are scripts under `mise-tasks/`; `mise tasks` lists them. They run against the polyrepo root, the parent of
this repository's git directory, also when invoked from a worktree of it; `repos.txt` is read from the checkout that
runs them. Subrepositories inherit the root `mise.toml`, so each task refuses to run when invoked from another
repository or below a nearer mise config: a subrepository defines its own `setup`, `lint` and the like.

| Task | Does |
|------|------|
| `setup` | `setup:clone`, `setup:hooks`, `setup:subrepos`, `setup:ai-rulez`; reports every failed step |
| `setup:clone` | Clone every registry repository that is not checked out yet; reports the ones that fail |
| `setup:hooks` | Provision hook preferences and install Poly hooks here and in every repository that declares hooks |
| `setup:subrepos` | Run `mise run setup` in each repository that defines a mise `setup` task; reports the ones that fail |
| `setup:ai-rulez` | `ai-rulez generate --gitignore`: the root, then `--recursive` inside each repository |
| `ai-rulez:check` | Fail when any root's generated output is stale, or when a generated file is neither tracked nor gitignored |
| `ai-rulez:update` | Move every repository's version-range pins (agent-conventions includes; skills that use ranges) to the newest allowed release, then run `setup:ai-rulez` |
| `repos:status` | Per repository: branch, changed files, ahead/behind its upstream (no fetch) and worktree count; flags missing repositories and any the root `.gitignore` does not ignore |
| `repos:pull` | Fetch all repositories and fast-forward those that are only behind; reports diverged or blocked ones |
| `worktree:add <repo> <branch> [--base <ref>]` | Create a worktree at `.worktrees/<repo>/<branch>`, with characters outside `A-Za-z0-9_-` replaced by `-`; a new branch starts from `origin/HEAD` |
| `worktree:remove <repo> <branch>` | Remove that worktree (the branch stays) |
| `governance:hooks:install` | Provision hook preferences and install Poly hooks in the root only (`setup:hooks` runs it first) |
| `lint`, `format`, `format:check` | Poly over the root files, with shfmt and ShellCheck for the task scripts |

Development tasks for a project live in that repository: `mise -C <repo> tasks`.

### Checking generated configuration

`mise run ai-rulez:check` prints one line per root:

```text
.                            63 outputs: 60 ignored, 3 tracked
gitfluff                     83 outputs: 62 ignored, 21 tracked
uncomment                    83 outputs: 78 ignored, 4 tracked, 1 NEITHER: AGENTS.md
```

Tracked outputs are committed on purpose: the `.ai-rulez/**/index.md` files, and whatever a repository lists in
`gitignore_exclude` (gitfluff, go-utils and starmetal commit their `AGENTS.md`/`CLAUDE.md` and some agent and skill
files). An output that is NEITHER would show up as a new untracked file after generate: fix that repository's
`.gitignore` or `gitignore_exclude`, then rerun `mise run setup:ai-rulez`.

## Working with agents

Start an agent (Claude Code, Codex or OpenCode) at this root. The generated `AGENTS.md`/`CLAUDE.md` carry the
workspace conventions, and the ai-rulez MCP server serves the shared skills on demand. A typical session:

```sh
mise run repos:pull
mise run repos:status
mise run worktree:add spikard fix/router-params
claude   # or codex, opencode; point it at .worktrees/spikard/fix-router-params
```

Run one worktree per agent so parallel agents never share a checkout, and remove it with `mise run worktree:remove`
once the branch is merged. Inside a repository, that repository's own `AGENTS.md`/`CLAUDE.md` and mise tasks take
precedence. The `polyrepo-development` rule in `.ai-rulez/rules/` holds the workspace conventions.

## AI governance

Authored configuration is in [`.ai-rulez/`](.ai-rulez/); `AGENTS.md`, `CLAUDE.md` and the per-harness files
(`.claude/`, `.codex/`, `.opencode/`, `.agents/`, `.mcp.json`, `opencode.json`) are generated and gitignored. The
root includes `modules/core` from agent-conventions by version range (`version = "^1"`), and the lock records the
exact commit. It follows the same layout as the xberg-io root: `compact = true`, glob-scoped rules served through
`[rules] scoped_fallback = "skill"`, the ai-rulez MCP server restricted to `find_skill` and `load_skill`, and an
area map in `.ai-rulez/context/`.

To change a shared rule, edit it in agent-conventions, push, tag a release, then run `mise run ai-rulez:update`:
it runs `ai-rulez update` in the root and every repository, then regenerates through `setup:ai-rulez`. Preview with
`ai-rulez lock --outdated` or `ai-rulez update --dry-run`. To regenerate and verify here:

```sh
ai-rulez validate --strict --no-local
ai-rulez lock
ai-rulez generate --no-local --strict-config
ai-rulez generate --check --no-local --strict-config
```

CI (`.github/workflows/ai-rulez-validation.yml`) validates the sources and generated outputs with the shared
`setup-ai-rulez` and `validate-ai-rulez` actions.
