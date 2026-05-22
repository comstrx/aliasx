# Changelog

## v0.1.2 - Self-Hosting Forge Release

### Added

- Added the `forge` module as the main project lifecycle engine.
- Added Bash project semantic fallback support through `entry sh`.
- Added aliasx-style command forwarding for Bash projects:
  - `build`
  - `check`
  - `install`
  - `build-release`
  - `remove`
  - `run`
  - `start`
  - `test`
- Added self-hosting support so `aliasx` can build, test, install, and release itself through its own lifecycle commands.
- Added smart bundled command runner normalization:
  - lowercase variants
  - uppercase variants
  - capitalized variants
- Added release execution through semantic forwarding, allowing `run release` to execute the project release flow.
- Added stronger Bash lifecycle fallbacks:
  - direct script files like `build.sh`, `check.sh`, `run.sh`
  - `src/*.sh` lifecycle scripts
  - bundled entry command forwarding
  - safe fallback behavior.
- Added `forge` support for Bash, PHP, Python, Rust, Go, Zig, C/C++, Node, Bun, Dart, Java, .NET, Lua, and Mojo.
- Added installer semantic support so Bash projects can use `install.sh`, `src/install.sh`, or `main.sh install`.
- Added remove semantic support through `del.sh`, `remove.sh`, `uninstall.sh`, and bundled `remove` command fallback.
- Added stronger test semantic support through `test.sh`, `tests.sh`, `src/test.sh`, `src/tests.sh`, and bundled `test` command fallback.

### Changed

- Renamed the project lifecycle module from `stack` to `forge`.
- Reworked Bash project handling to support aliasx command semantics as a fallback.
- Improved the generated bundle entrypoint using a compact heredoc-based runner.
- Improved command dispatch behavior for bundled functions.
- Improved project structure into clearer modular domains:
  - `core`
  - `file`
  - `forge`
  - `github`
  - `stack`
- Improved release flow so the project can release itself through the generated bundle.
- Improved local install flow and verified direct sourcing from `~/.local/bin/ax`.

### Fixed

- Fixed command dispatch limitations for function names using hyphens and underscores.
- Fixed Bash project lifecycle detection gaps.
- Fixed self-hosting lifecycle behavior for `run`, `build-release`, and `install`.
- Fixed ShellCheck issues in the generated bundle workflow.
- Fixed stale monolithic module layout by splitting GitHub, file, forge, and core logic.

---

## v0.1.1 - Modular GitHub and Tooling Upgrade

### Added

- Added modular GitHub command groups:
  - `base`
  - `branch`
  - `cache`
  - `clone`
  - `env`
  - `flow`
  - `fork`
  - `gist`
  - `info`
  - `init`
  - `issue`
  - `open`
  - `prs`
  - `push`
  - `release`
  - `repo`
  - `rollback`
  - `ssh`
  - `tag`
  - `var`
- Added file utility modules:
  - `backup`
  - `encode`
  - `env`
  - `key`
  - `sync`
- Added core system modules:
  - `env`
  - `log`
  - `ops`
  - `sys`
- Added GitHub Actions workflow helpers.
- Added GitHub cache listing and clearing helpers.
- Added GitHub run listing, viewing, watching, rerunning, and cancellation helpers.
- Added GitHub workflow listing, viewing, enabling, disabling, and triggering helpers.
- Added GitHub environment management helpers.
- Added repository metadata helpers for owner, name, repo, branch, tag, version, and status.
- Added archive and sync helpers for local project backups and mirrors.
- Added key encoding helpers for environment files, SSH keys, and PEM keys.
- Added cross-platform clipboard support.
- Added cross-platform URL opening helpers.
- Added system detection helpers for Linux, macOS, WSL, MSYS, Git Bash, Cygwin, Windows, CI, containers, GUI, and headless environments.
- Added package manager detection and binary install/remove/ensure helpers.
- Added empire-style tool bootstrap foundations through tool resolution and install helpers.
- Added doctor-style tool validation foundations for checking whether required tools are installed.

### Changed

- Split the previous large modules into smaller focused files.
- Improved GitHub release behavior with stronger tag, asset, changelog, and release handling.
- Improved local tool installation flow through package manager abstraction.
- Improved command naming consistency across GitHub helpers.
- Improved backup/sync behavior with ignore-aware exclusions.
- Improved logging and output separation between data output and diagnostic messages.
- Improved portability across Linux, macOS, WSL, Git Bash, MSYS, and CI environments.

### Fixed

- Fixed several ShellCheck warnings across bundled output.
- Fixed GitHub helper naming collisions.
- Fixed process handling helpers for show/stop behavior.
- Fixed package install resolution through `bin:package:version` specs.
- Fixed generated bundle stability after modular splitting.

---

## v0.1.0 - Initial Public Release

### Added

- Added the first public release of `aliasx`.
- Added a self-contained Bash bundle generator.
- Added development and release bundle targets.
- Added command runner support for bundled functions.
- Added installer support for local user binaries.
- Added optional shell profile integration.
- Added test discovery and execution.
- Added generated bundle validation with `bash -n` and `shellcheck`.
- Added Git/GitHub workflow helpers.
- Added lifecycle commands for build, run, install, test, check, and release.
- Added GitHub Actions CI workflow.
- Added project documentation:
  - `README.md`
  - `LICENSE`
  - `SECURITY.md`
  - `CHANGELOG.md`
