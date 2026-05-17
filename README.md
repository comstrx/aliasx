# ✨ Aliasx

<div align="center">
  <img height="300" alt="logo" src="https://github.com/user-attachments/assets/015fee36-fc97-4c99-9f99-147b19382f38" />
</div>

![CI](https://github.com/comstrx/aliasx/actions/workflows/ci.yaml/badge.svg)
![License](https://img.shields.io/github/license/comstrx/aliasx)
![Release](https://img.shields.io/github/v/release/comstrx/aliasx)

`aliasx` is a small Bash-based command framework for running a self-contained shell command bundle.

It is designed to turn a modular Bash codebase into one executable CLI file.

## Features

- Build dev and release bundles
- Run bundled commands
- Install the CLI into `~/.local/bin`
- Source installed commands into the current shell
- Lightweight test discovery
- Optional ShellCheck validation
- Project sync / backup / repo helpers through modules
- Simple modular layout

## Quick Install

Install the latest release bundle as `ax`:

```bash
curl -fsSL https://github.com/comstrx/aliasx/releases/latest/download/ax.sh -o ~/.local/bin/ax
chmod +x ~/.local/bin/ax
```

Optional: load aliasx automatically in future shells:

```bash
printf '\n# aliasx\n[ -f "$HOME/.local/bin/ax" ] && source "$HOME/.local/bin/ax"\n' >> ~/.bashrc
source ~/.bashrc
```

Now you can run bundled commands directly:

```bash
root
repo
status
now
year
sec
rand
```

## Development Install

Clone the repository if you want to customize, extend, or build your own command bundle:

```bash
git clone https://github.com/comstrx/aliasx.git
cd aliasx
```

Add your own commands under:

```bash
src/mod/
```

Then rebuild and reinstall:

```bash
bash src/main.sh test --check
bash src/main.sh install
```

## Usage

```bash
bash src/main.sh build          # Build dev bundle into target/dev
bash src/main.sh build-release  # Build release bundle into target/release
bash src/main.sh check          # Run bash -n and ShellCheck on the final bundle
bash src/main.sh test           # Run tests from the dev bundle
bash src/main.sh test --check   # Run checks, then tests
bash src/main.sh run CMD        # Run a bundled command
bash src/main.sh install        # Install release bundle into ~/.local/bin
bash src/main.sh release        # Build and publish a GitHub release
```

## Tests

Tests are discovered from functions that either:

1. Start with `test_`

```bash
test_example () {
    assert_eq "1" "1"
}
```

2. Or are marked with one of:

```bash
# test
# [test]
# @[test]
```

Example:

```bash
# test
hello_world () {
    assert_eq "Done" "Done"
}
```

To exclude a test, use:

```bash
# no_test
# no-test
# [no-test]
```

This exclusion wins even if the function starts with `test_`.

## Assertions

Basic assertions are available:

```bash
assert_eq "actual" "expected"
assert_ne "actual" "unexpected"
```

## CI

The project uses GitHub Actions:

```yaml
- name: Run test
  run: bash src/main.sh test --check
```

## Requirements

* Bash
* ShellCheck

Optional modules may require extra tools depending on the command used.

## Why aliasx?

Bash aliases are fast, but hard to structure.
Shell scripts are powerful, but annoying to bundle.
`aliasx` gives you a tiny framework to build, test, release, and install one portable CLI from modular shell files.

## Philosophy

- One command bundle
- Zero runtime dependency beyond Bash
- Modular source, portable output
- Fast personal automation
- Simple enough to understand, useful enough to keep

## Contributing

This project is intentionally small and practical.

If you want to extend it:

2. Add shared helpers under `src/core/`
1. Add commands under `src/mod/`
3. Add tests under `tests/`
4. Run:

```bash
bash src/main.sh test --check
```

## License

See [LICENSE](./LICENSE). Commercial usage outside the license terms requires written permission.
