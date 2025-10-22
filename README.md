# minijinja-xcframework

Builds and publishes XCFrameworks for [minijinja](https://github.com/mitsuhiko/minijinja).

## Prerequisites

- macOS with Xcode installed
- Rust toolchain
- [just](https://github.com/casey/just) command runner

## Installation

Install `just`:

```bash
# Using Homebrew
brew install just

# Or using cargo
cargo install just
```

## Building

### Build Everything

To build the complete XCFramework:

```bash
just build
```

Or specify a minijinja version:

```bash
MINIJINJA_VERSION=2.1.0 just build
```

### Available Commands

View all available commands:

```bash
just --list
```

#### Top-Level Commands

- `just clean` - Clean build and output directories
- `just clone-minijinja` - Clone minijinja from upstream
- `just install-targets` - Install all Rust cross-compilation targets
- `just build-all` - Build all platform targets
- `just create-fat-binaries` - Create universal binaries for simulators and macOS
- `just create-xcframework` - Assemble the XCFramework
- `just package` - Create distribution zip and compute checksum
- `just build` - Run complete build process (all steps above)

#### Platform-Specific Commands

- `just build-ios` - Build all iOS targets (device + simulator)
- `just build-catalyst` - Build all Mac Catalyst targets
- `just build-macos` - Build all macOS targets
- `just build-tvos` - Build all tvOS targets
- `just build-watchos` - Build all watchOS targets
- `just build-visionos` - Build all visionOS targets

### Build Architecture

The justfile uses a hierarchical structure:

1. **Top-level commands** orchestrate major build steps
2. **Platform commands** depend on target-specific builds
3. **General-purpose commands** handle individual targets with parameters

All architectures, platforms, SDKs, and targets are defined as constants at the top of the justfile, making it easy to maintain and update.

## Output

After building, you'll find:

- `output/minijinja.xcframework` - The XCFramework
- `output/minijinja.xcframework.zip` - Distribution archive
- Checksum printed to console for Swift Package Manager

## Supported Platforms

- iOS 26.0+ (arm64 device, universal arm64/x86_64 simulator)
- macOS 26.0+ (universal arm64/x86_64)
- Mac Catalyst 26.0+ (universal arm64/x86_64)
- tvOS 26.0+ (arm64 device, universal arm64/x86_64 simulator)
- watchOS 26.0+ (arm64 device, universal arm64/x86_64 simulator)
- visionOS 26.0+ (arm64 device, arm64 simulator)
