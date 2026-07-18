# Security Policy

## Project status

Toolkitty is pre-release alpha software undergoing maintenance recovery. It has not received a security audit, has no supported stable release, and should not currently be used for sensitive or production coordination data.

Known security-relevant limitations are being triaged, including incomplete access-request encryption, inbound message validation, durable backend persistence, and release signing. Do not assume all application data or metadata is end-to-end encrypted. Build artifacts should be treated as unsigned unless a release explicitly states otherwise.

Security reports affecting the current `main` branch are welcome and will be handled on a best-effort basis. Historical snapshots and unofficial third-party builds are not supported.

## Reporting a vulnerability

Please do not open a public issue containing vulnerability details, credentials, personal data, or exploit code.

1. Use GitHub's private vulnerability reporting flow at [Report a vulnerability](https://github.com/0cwa/toolkitty/security/advisories/new).
2. If that flow is unavailable, contact [@0cwa](https://github.com/0cwa) through GitHub without including sensitive details in public. A private reporting channel can then be arranged.

Include, where possible:

- the affected commit, version, and platform;
- the vulnerable component and prerequisites;
- minimal reproduction steps or proof of concept;
- likely impact and whether the issue is already public;
- any suggested mitigation.

The maintainer will try to acknowledge a report within seven days. Investigation and remediation timelines depend on severity, reproducibility, and maintainer availability; this is not a guaranteed service-level agreement. Reporters will be credited when desired and when disclosure is safe.

## Scope

Reports about Toolkitty's application code, Tauri configuration, update/release process, local data handling, peer-to-peer protocol integration, or project-controlled CI are in scope. Vulnerabilities solely in an upstream dependency should normally be reported to that upstream project, but please also notify Toolkitty privately when the dependency makes this project exploitable.

For non-security bugs and support, see [SUPPORT.md](SUPPORT.md).
