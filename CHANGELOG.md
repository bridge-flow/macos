# Changelog

BridgeFlow follows small, explicit releases. Dates use UTC.

## Unreleased

- Improved first-run permission setup with automatic refresh, auto-advance and clearer Local Network status.
- Added a drag-and-drop desk layout that syncs peer positions in real time.
- Added local and remote peripheral inventory for shared input devices.
- Added a first-run permission setup flow for Accessibility, Input Monitoring and Local Network access.
- Added Dashboard input-capture status so missing macOS permissions are visible before edge switching.
- Starts Bonjour advertising when the app opens, so local Macs can appear before input capture starts.
- Makes Bonjour discovery tolerant of services that arrive before their TXT metadata.
- Added Bonjour discovery for local BridgeFlow peers.
- Added signed and notarised macOS release packaging with zip and DMG artefacts.
- Added CI and draft release workflows.
- Added SwiftPM packaging for `BridgeFlow.app`.
- Added native macOS MVP with host/client modes, input capture, event injection, manual peer connection, edge switching and menu bar controls.
