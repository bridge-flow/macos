# BridgeFlow

One flow. Every Mac.

BridgeFlow is an open-source macOS utility for seamless keyboard and mouse control across multiple Macs. It is built with Swift, SwiftUI, AppKit where needed, CoreGraphics and Network.framework, using only public macOS APIs.

## Features

- Native SwiftUI macOS app with a menu bar extra.
- Host, Client and Both modes.
- Global input capture on the host with `CGEventTap`.
- Local event injection on the client with `CGEventPost`.
- Manual local-network connection by IP address and port.
- JSON newline-delimited protocol for easy debugging.
- Left, right, above and below layout configuration, with MVP edge switching for left and right flows.
- Accessibility and Input Monitoring permission status.
- Pairing code and trusted-peer storage in UserDefaults.
- Logs, connection status, latency and peer controls.

## Requirements

- macOS 13 or later.
- Xcode command line tools with Swift 5.9 or newer.
- Accessibility permission on Macs receiving injected input.
- Input Monitoring permission on Macs capturing global input.

## Permissions

BridgeFlow needs Accessibility so the client can post keyboard and mouse events locally. It needs Input Monitoring so the host can listen to global keyboard and mouse events. The app shows both states in the Permissions view and provides buttons to open System Settings.

## How To Run

Run the tests and build:

```bash
make test check build
```

Launch the app bundle:

```bash
./script/build_and_run.sh
```

Open the package in Xcode by opening `Package.swift`, then select the `BridgeFlow` executable target.

## How Pairing Works

The MVP uses a six-digit manual pairing code. A peer is trusted only after the code matches, and trusted peer IDs are stored in UserDefaults. The current protocol is intentionally simple for local debugging and future hardening.

## Security Notes

- The MVP is designed for local network use only.
- The default port is `48765`.
- Manual IP pairing is implemented; Bonjour discovery is prepared but not active.
- Encryption is planned but not implemented yet.
- Do not expose the port directly to the internet.

## Limitations

- iPad global input injection is not supported by public iPadOS APIs.
- Universal Control APIs are private and are not used.
- MVP uses manual IP pairing.
- Encryption is planned but not implemented yet.
- Clipboard sync is not part of the MVP.

## Roadmap

See `TODO.md`.

## Contributing

Contributions should keep the project dependency-free for the MVP, use public Apple APIs only, include focused tests for core logic and preserve the native macOS experience.

## License

MIT. See `LICENSE`.
