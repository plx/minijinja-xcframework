# Guide for Agents

This repository exists to facilitate the development of [hdxl-swift-minijinja](https://github.com/plx/hdxl-swift-minijinja), which is (will be) a Swift wrapper around the Rust-language templating engine [`minijinja`](https://github.com/mitsuhiko/minijinja); the wrapping will be done via `minijinja`'s C-ABI subtarget, which exposes its functionality in a C-compatible form.

As such, the structure of this repository is like so:

- `justfile`: the justfile contains our "build script", structured as a sequence of commands:
  - cleaning and fetching the upstream `minijinja` source code
  - building `minijinja` for each supported platform
  - creating universal (fat) binaries for each platform
  - verifying that the headers are properly modularized
  - creating the final XCFramework
  - packaging the XCFramework for distribution
  - updating the `README.md` with the latest version and checksum
- `.github/workflows/build-release.yml`: a Github Actions workflow that automatically builds and publishes new releases whenever a new `minijinja` version is released

That's the intent, but but we're not quite there—still getting things fully-working.

# Notes

- As of this summer, Apple has moved to uniform, year-based versions for all platforms and tools: iOS 18 is followed by iOS 26, visionOS 2 is followed by visionOS 26, the latest Xcode is 26, and so on; to enable these versions in a Package.swift file requires using the 6.2 versions of the tooling (`// swift-tools-version: 6.2`).
