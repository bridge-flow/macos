# Security Policy

BridgeFlow controls local input, so security issues matter even while the project is young.

## Supported Versions

Only the current `main` branch is actively supported until the first stable release.

## Reporting a Vulnerability

Please report vulnerabilities through GitHub Security Advisories when available. If that is not available, open a minimal issue that says a security report is available and avoid posting exploit details publicly.

Useful reports include:

- macOS version.
- BridgeFlow commit or release version.
- Network setup.
- Whether the issue affects pairing, trusted peers, input capture, event injection or local storage.

## Current Security Limits

The MVP is for trusted local networks only. Manual pairing exists, but transport encryption is not implemented yet. Do not expose the BridgeFlow port directly to the internet.
