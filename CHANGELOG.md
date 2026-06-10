# Changelog

## v0.1.6 - Workspace Semantics

- Added `WORKSPACE_DIR` roots with an explicit-vs-inferred source contract for sync and backup.
- Added workspace resolution: inferred sources climb to the project root from any depth.
- Added `--force` to sync and backup the current directory without workspace resolution.
- Added `fleet-sync` for mono push with local-only fleet distribution.
- Improved env defaults with chained fallbacks for owner, workspace, sync, and archive paths.

---

## v0.1.5 - Fleet Orchestration

- Added the `fleet` multi-dist orchestrator with data-driven targets (`dest:org:prefix`).
- Added `fleet-fine`, `fleet-ship`, and `fleet-release` escalation wrappers.
- Added protected files, mono-owned root configs, and seed-once repositories.
- Added on-demand leaf init/attach and trace messages (`tag@sha@commit`) on every leaf commit.
- Added `fine`, `ship`, `release`, and `gone` current-repo lifecycle wrappers.
- Verified live fan-out across 16 repositories in 3 organizations.

---

## v0.1.4 - Release Pipeline Hardening

- Reworked `push` with explicit force flags, unborn-branch handling, and integrated tagging.
- Reworked `new-release` with a tag-first contract, release editing, asset checksums, and changelog detection.
- Reworked `new-tag` and `del-tag` with opt-in force and accountable remote deletion.
- Reworked `init` with zero implicit creation: bootstrap, attach to existing, or explicit `--create`.
- Added `rollback` HEAD snapshots with restoration on push failure.
- Fixed subshell returns, silent remote failures, and positional contract drift across the GitHub module.

---

## v0.1.3 - Empire Ready

- Added Bash/runtime guard helpers.
- Added core tool install/remove/ensure helpers.
- Added forge helpers for version, path, and usage.
- Improved encode/decode, sync, and system utilities.
- Verified check, test, build, install, and sync flow.

---

## v0.1.2 - Self-Hosting Forge Release

- Added the `forge` lifecycle engine: build, check, test, install, run, remove, and release.
- Added language support for Bash, PHP, Python, Rust, Go, Zig, C/C++, Node, Bun, Dart, Java, .NET, Lua, and Mojo.
- Added Bash semantic fallbacks through lifecycle scripts and bundled command forwarding.
- Added self-hosting so aliasx builds, tests, installs, and releases itself.
- Renamed the lifecycle module from `stack` to `forge` and split logic into core, file, forge, github, and stack domains.
- Fixed hyphenated command dispatch and ShellCheck issues in the generated bundle.

---

## v0.1.1 - Modular GitHub and Tooling Upgrade

- Added modular GitHub groups: repos, branches, tags, releases, envs, vars, issues, PRs, gists, SSH, caches, and workflows.
- Added file utilities for backup, sync, encode, env, and key handling.
- Added core system modules with cross-platform detection for Linux, macOS, WSL, MSYS, CI, and containers.
- Added package manager abstraction with install/remove/ensure helpers.
- Improved output separation, naming consistency, and ignore-aware backup/sync behavior.
- Fixed ShellCheck warnings, naming collisions, and bundle stability after the modular split.

---

## v0.1.0 - Initial Public Release

- Added the self-contained Bash bundle generator with development and release targets.
- Added lifecycle commands for build, run, install, test, check, and release.
- Added bundle validation with `bash -n` and ShellCheck.
- Added Git/GitHub workflow helpers and a GitHub Actions CI workflow.
- Added a local installer with optional shell profile integration.
- Added project documentation: README, LICENSE, SECURITY, and CHANGELOG.
