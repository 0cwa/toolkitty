# Maintenance Roadmap

Toolkitty resumed active maintenance in the `0cwa/toolkitty` fork after an extended inactive period. The project remains pre-release alpha software. The immediate goal is a trustworthy development baseline, not a rush to declare feature completeness or publish production installers.

## Recovery Baseline

The first bounded milestone covers:

1. Reproducible Node, npm, and Rust toolchains with lockfile-based installs.
2. Pull-request CI for frontend tests, type checking, linting, formatting, and builds, plus Rust tests, checks, formatting, and Clippy.
3. Controlled packaging and release automation that does not create a release on every `main` push.
4. Core contributor, support, security, ownership, and issue-triage documentation.
5. A clean desktop build and a documented smoke-test pass for cold start, restart, calendar creation/joining, event and booking updates, access rejection, malformed input, timezone handling, and uploads.
6. Reproduction and scoping of security, persistence, authorization, scheduling, and P2P data-integrity blockers before any user-facing release claim.

A green pipeline is necessary but is not evidence that Toolkitty is secure, durable, or ready for production data.

## Deliberate deferrals

The following work should remain in separate, reviewable tranches:

- **P2P architecture migration.** The Rust backend pins the archived `experimental-node` repository and older p2panda git revisions. Migrating away from them can change storage, networking, sync, and protocol semantics, so it requires a dedicated design and compatibility effort rather than an opportunistic dependency bump.
- **Signing and notarization.** Production signing, Apple notarization, Windows signing, secure secret custody, and update-channel design follow reproducible unsigned packaging. Until completed, artifacts must be described as unsigned development or pre-release artifacts.
- **Mobile CI and distribution.** Android and Apple projects exist, but desktop build health comes first. Mobile build matrices, device testing, store metadata, signing, and distribution are not part of the Recovery Baseline.
- **Major framework and protocol upgrades.** Major SvelteKit, Vite, Tauri, Rust-edition, database, or P2P changes should be isolated, tested, and documented. Avoid combining them with product fixes or release-pipeline work.
- **Broad feature and styling backlog.** New exports, splash screens, large styling branches, speculative abstractions, and broad UX redesigns wait until core workflows and data handling are reliable.

## Issue triage principles

Use four practical buckets:

- **Release blocker:** reproducible security, authorization, data-loss, persistence, scheduling, cross-calendar privacy, or core create/join/booking failure.
- **Maintenance:** current-platform bugs, test gaps, contained refactors, documentation, observability, and lifecycle cleanup that improve a working alpha.
- **Later:** new features, design polish, speculative architecture, or major changes that do not stabilize current behavior.
- **Stale or superseded:** old-environment reports, duplicate tracking issues, or work represented by an obsolete branch. Reproduce or compare against `main` before closing or porting it.

Issue age, an old assignee, or an expired milestone does not establish priority. Prefer reproducible evidence, user impact, security boundaries, and the smallest independently testable change. Do not carry old branches or pull requests wholesale when a small reimplementation against current `main` is safer.

## Release readiness

Before the first maintained pre-release, version values must agree across JavaScript, Cargo, and Tauri configuration; required CI must pass; release notes must identify known limitations; artifacts must clearly state their signing status; and the security/data-persistence caveats in [SECURITY.md](SECURITY.md) must be reviewed.
