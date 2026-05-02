# Contributing

Thanks for helping make BridgeFlow better.

The project is intentionally conservative in the MVP:

- Use public Apple APIs only.
- Keep the app native: Swift, SwiftUI, AppKit where needed.
- Avoid new dependencies unless they solve a real maintenance problem.
- Keep networking debuggable and local-network first.
- Add focused tests for core logic.

## Local Setup

```bash
git clone git@github.com:bridge-flow/macos.git
cd macos
swift test
swift build
```

## Pull Requests

Before opening a pull request:

```bash
swift test
swift build
```

Keep pull requests small enough to review. For user-facing changes, include screenshots or a short screen recording. For input, networking or permission changes, describe the Macs and macOS versions used for testing.

## Code Style

Prefer simple Swift over clever abstractions. Follow the existing file layout and naming. Comments are useful when they explain a platform edge case; avoid comments that repeat the code.

## Release Changes

Changes that affect packaging, permissions, pairing or network security should update the README and TODO where relevant.
