# Changelog

BridgeFlow follows small, explicit releases. Dates use UTC.

## Unreleased

- Starts Bonjour advertising when the app opens, so local Macs can appear before input capture starts.
- Makes Bonjour discovery tolerant of services that arrive before their TXT metadata.
- Added Bonjour discovery for local BridgeFlow peers.
- Added signed and notarised macOS release packaging with zip and DMG artefacts.
- Added CI and draft release workflows.
- Added SwiftPM packaging for `BridgeFlow.app`.
- Added native macOS MVP with host/client modes, input capture, event injection, manual peer connection, edge switching and menu bar controls.
