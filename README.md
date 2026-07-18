# Toolkitty 😻

> Autonomous coordination toolkit for collectives, organisers and venues to share resources and organise events in a collaborative calendar.

Toolkitty is built for iOS, Android and Desktop with [Tauri](https://tauri.app/), [SvelteKit](https://svelte.dev/) and [p2panda](https://p2panda.org/).

## About

Toolkitty is a peer-to-peer (P2P), [local-first](https://www.inkandswitch.com/local-first/) application for desktop and mobile designed to help collectives, festivals, organizers, venues and community spaces by facilitating decentralized resource exchanging and event coordination in a collaborative calendar. We are building it for groups that value autonomy, resilience, and privacy in their organisational practices.

> [!WARNING]
> Toolkitty is pre-release alpha software undergoing maintenance recovery. It is not ready for production or sensitive coordination data, has not received a security audit, and currently has known persistence, validation, encryption, and release-signing gaps. See [Security](SECURITY.md) and the [maintenance roadmap](MAINTENANCE.md).

### Key features

- **Peer-to-Peer Networking.** Using p2panda under the hood, networking is done directly between peers instead of using a centralised server.
- **Local-first direction.** The interface stores working data locally and can sync with peers, while durable backend persistence and recovery behavior are still being hardened.
- **Resource Sharing.** Easy to list, discover and manage shared resources like spaces and tools or equipment, encouraging sustainable and collaborative practices.
- **Shared Calendar and Events.** Plan your venue, festival, collective through a shared calendar.
- **Privacy-oriented design.** Toolkitty aims to minimize central infrastructure, but its security model is incomplete. Do not assume all data or metadata is end-to-end encrypted.

## Project status

The original mid-2025 launch target passed without a stable release. Maintenance resumed in the [`0cwa/toolkitty`](https://github.com/0cwa/toolkitty) fork with a desktop-first recovery baseline. Mobile projects remain experimental, and there is currently no supported stable release or production distribution channel.

Maintenance work is deliberately staged: restore reproducible builds and CI, verify core workflows and security boundaries, then address confirmed release blockers before expanding features. See [MAINTENANCE.md](MAINTENANCE.md) for scope and deferrals, [CONTRIBUTING.md](CONTRIBUTING.md) to help, and [SUPPORT.md](SUPPORT.md) when reporting a problem.

## Development

Make sure you have installed the prerequisites for your OS: https://tauri.app/start/prerequisites/, then run:

```bash
# Install dependencies
npm ci

# Initialize environments for Android and iOS development
npm run tauri android init
npm run tauri ios init

# Start Desktop application in development mode
npm run tauri dev

# Start Android app in development mode
npm run tauri android dev

# Start iOS app in development mode
npm run tauri ios dev

# For testing the p2p functionality you can run the application multiple times
# on the same machine, repeat this command per peer you want to launch
npm run peer
```

## License

[`GPL-3.0 license`](/LICENSE)
