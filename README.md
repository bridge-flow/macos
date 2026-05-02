# BridgeFlow

[![CI](https://github.com/bridge-flow/macos/actions/workflows/ci.yml/badge.svg)](https://github.com/bridge-flow/macos/actions/workflows/ci.yml)
[![Release](https://github.com/bridge-flow/macos/actions/workflows/release.yml/badge.svg)](https://github.com/bridge-flow/macos/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black.svg)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)

One flow. Every Mac.

BridgeFlow is a native macOS utility for sharing one keyboard and mouse across multiple Macs. It aims for the feel of Logitech Flow or Universal Control, while staying open-source and using public macOS APIs only.

The project is early, practical, and intentionally small: Swift, SwiftUI, AppKit where needed, CoreGraphics, Network.framework, Combine and UserDefaults. No Electron, no private APIs, no third-party runtime dependencies in the MVP.

## What Works Today

- Native SwiftUI app with a main window and menu bar extra.
- Host, Client and Both modes.
- Global keyboard and mouse capture on the host with `CGEventTap`.
- Local keyboard and mouse injection on the client with `CGEventPost`.
- Manual peer connection by IP address and port.
- Newline-delimited JSON protocol that is easy to inspect while developing.
- Layout configuration for left, right, above and below.
- MVP edge switching for left/right workflows.
- Accessibility and Input Monitoring permission checks.
- Pairing code flow with trusted peer IDs stored in UserDefaults.
- Local logs, connection status, latency display and peer controls.

## Install

### Option 1: Download a release

1. Open the [Releases](https://github.com/bridge-flow/macos/releases) page.
2. Download the latest `BridgeFlow-<version>.zip`.
3. Unzip it and move `BridgeFlow.app` to `/Applications`.
4. Open BridgeFlow on each Mac you want to connect.

BridgeFlow is not notarised yet. Until signing and notarisation are in place, macOS may require Control-click > Open the first time you launch the app.

### Option 2: Build from source

```bash
git clone git@github.com:bridge-flow/macos.git
cd macos
make test check build
./script/build_and_run.sh
```

To produce a local `.app` bundle without launching it:

```bash
make package
open dist
```

## Set Up Two Macs

Install and open BridgeFlow on both Macs.

On the Mac with the keyboard and mouse you want to use, choose **Host** or **Both** mode. On the Mac that will receive input, choose **Client** or **Both** mode.

Grant permissions when prompted:

- **Input Monitoring** on any Mac that captures global input.
- **Accessibility** on any Mac that injects input locally.

Then connect manually:

1. Find the client Mac's local IP address.
2. On the host Mac, open **Peers**.
3. Enter the IP address and port `48765`.
4. Connect and trust the peer with the pairing code.
5. Open **Layout** and choose where the remote Mac sits.

For a two-way setup, run Both mode on both Macs and grant both permissions on both machines.

## Permissions

BridgeFlow asks for permissions only because macOS requires them for this class of utility.

- Accessibility allows BridgeFlow to post keyboard and mouse events.
- Input Monitoring allows BridgeFlow to listen for global keyboard and mouse events.

The app shows the current permission state in the Permissions view and links directly to System Settings.

## Security Model

The MVP is designed for trusted local networks.

- Default port: `48765`.
- Manual IP connection only.
- Manual pairing code before trusting a peer.
- Trusted peer IDs are stored in UserDefaults.
- Transport encryption is planned, but not implemented yet.

Do not expose BridgeFlow directly to the internet. TLS or a Noise-based encrypted pairing flow is on the roadmap.

## Development

Run the same checks used by CI:

```bash
make test check build
```

Regenerate icon assets:

```bash
make assets
```

Build a distributable app bundle:

```bash
make package
```

The CI workflow runs tests, builds the Swift package and packages `BridgeFlow.app` as an artefact. The release workflow runs on tags matching `v*` and creates a draft GitHub release with a zipped app bundle.

## Release

Create and push a version tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions will build the app, upload an artefact and create a draft release. Review the generated notes, test the zip on a clean Mac, then publish the release manually.

## Limitations

- iPad global input injection is not supported by public iPadOS APIs.
- Universal Control APIs are private and are not used.
- The MVP uses manual IP pairing.
- Encryption is planned but not implemented yet.
- Clipboard sync is not part of the MVP.
- Signing and notarisation are not wired up yet.

## Roadmap

See [TODO.md](TODO.md).

## Contributing

Bug reports, focused fixes and small feature branches are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

BridgeFlow is released under the permissive [MIT License](LICENSE).
