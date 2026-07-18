# Contributing to Toolkitty

Thank you for helping maintain Toolkitty. This fork is in an alpha recovery phase, so focused fixes, tests, documentation, and build improvements are especially useful.

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md) in all project spaces. For security-sensitive findings, use the private process in [SECURITY.md](SECURITY.md) instead of a public issue.

## Before you start

1. Search the [open issues](https://github.com/0cwa/toolkitty/issues) and existing pull requests.
2. For a bug, include a small reproduction and the affected platform. For a feature or substantial refactor, open an issue before investing in implementation.
3. Keep changes bounded. Dependency upgrades, product behavior, generated mobile projects, and broad refactors should normally be separate pull requests.

The current priorities and deferrals are documented in [MAINTENANCE.md](MAINTENANCE.md).

## Development setup

Install the [Tauri prerequisites for your operating system](https://v2.tauri.app/start/prerequisites/). Use the Node version in `.node-version`, the npm version declared by `packageManager` in `package.json`, and the Rust toolchain in `rust-toolchain.toml`.

Install JavaScript dependencies from the lockfile:

```bash
npm ci
```

Start the frontend or desktop application:

```bash
npm run dev
npm run tauri dev
```

For local peer-to-peer testing, start separate instances in separate terminals:

```bash
npm run peer
```

## Required checks

Run the checks relevant to your change before opening a pull request. For frontend or shared changes, run:

```bash
npm test
npm run check
npm run lint
npm run format
npm run build
```

For Rust or Tauri changes, also run:

```bash
cargo test --locked --manifest-path src-tauri/Cargo.toml --all-features
cargo check --locked --manifest-path src-tauri/Cargo.toml --all-targets --all-features
cargo fmt --manifest-path src-tauri/Cargo.toml --all -- --check
cargo clippy --locked --manifest-path src-tauri/Cargo.toml --all-targets --all-features --no-deps -- -D warnings
```

Platform-specific Tauri builds can require system packages and may be completed by CI. If a check cannot run locally, explain why in the pull request and report the checks you did run.

## Change guidelines

- Add or update tests for behavior changes and bug fixes.
- Avoid unrelated formatting or cleanup in the same pull request.
- Preserve both lockfiles when changing dependencies and explain why the upgrade is needed.
- Do not commit generated Android or Apple project changes unless the pull request is specifically about those projects.
- Do not weaken Tauri capabilities, content security policy, authorization, or validation without calling out the security impact.
- Update user or maintainer documentation when behavior, support, build, or release expectations change.

## Pull requests

Use a descriptive title and complete the pull request template. Link related issues, describe risk and rollback considerations, and include screenshots for visible changes. A maintainer may ask for a large change to be split so it can be reviewed and reverted safely.

By contributing, you agree that your contribution is licensed under the repository's [GPL-3.0 license](LICENSE).
