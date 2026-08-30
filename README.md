# MiniJinjaC XCFramework

This repository builds MiniJinja's experimental C ABI as a static, multi-platform
XCFramework for Swift Package Manager. The distributed module is named
`MiniJinjaC`; it is intended to sit behind the native Swift API in
[`hdxl-swift-minijinja`](https://github.com/plx/hdxl-swift-minijinja).

The default build is deliberately immutable:

- source: [`plx/minijinja`](https://github.com/plx/minijinja)
- ref: `2.24.0`
- commit: `0ca749f7ba507514fa6b052c74130ae6ae472e03`
- stable Rust: `1.90.0`
- nightly Rust: `nightly-2025-11-04`

The fork's `2.24.0` tag is synchronized to the official upstream commit. The
repository, ref, and expected commit remain configurable for experiments and
future major-version evaluation.

## Build

Requirements are a Mac with Xcode 26.6 or newer, `rustup`, and
[`just`](https://github.com/casey/just). A complete clean build is:

```sh
just build
```

That command installs the pinned Rust toolchains, fetches and verifies the exact
source commit, builds every architecture, creates and verifies the XCFramework,
runs a SwiftPM integration test, and packages the release artifacts.

To build a different immutable revision:

```sh
MINIJINJA_REPOSITORY=https://github.com/plx/minijinja.git \
MINIJINJA_REF=2.24.0 \
MINIJINJA_EXPECTED_COMMIT=0ca749f7ba507514fa6b052c74130ae6ae472e03 \
just build
```

`MINIJINJA_SOURCE_DIR` may point at an existing local checkout. Its `HEAD` must
match `MINIJINJA_EXPECTED_COMMIT`. An empty expected commit opts out of that
guard for local experiments; release CI never does.

Useful focused commands include:

```sh
just configuration
just build-slices macos
just create-xcframework
just verify
just package
just lint
just test-module
```

## Binary contract

The release asset is `MiniJinjaC.xcframework.zip`, containing
`MiniJinjaC.xcframework`. SwiftPM clients use:

```swift
.binaryTarget(
  name: "MiniJinjaC",
  url: "https://github.com/plx/minijinja-xcframework/releases/download/minijinja-2.24.0-2/MiniJinjaC.xcframework.zip",
  checksum: "<value from the release>"
)
```

Source targets depend on `MiniJinjaC` and write `import MiniJinjaC`. Every slice
contains:

- `libMiniJinjaC.a`
- the upstream `minijinja.h`
- `module.modulemap`

The XCFramework root also contains `Licenses/` with MiniJinja's Apache-2.0
license, full notices from every linked Cargo dependency, and the copyright and
license documents for both pinned Rust runtimes. These files travel inside the
SwiftPM-downloaded archive. Release assets additionally include the exact
Cargo.lock and an SPDX SBOM.

The bundle deliberately contains no API notes. Functions, enum values, pointer
optionality, and ownership all retain their raw Clang-imported representation.
The higher-level Swift target owns every source-level refinement.

## Platforms and architectures

| Platform | Minimum | Device | Simulator |
| --- | ---: | --- | --- |
| macOS | 12.0 | arm64, x86_64 | — |
| iOS | 15.0 | arm64 | arm64, x86_64 |
| Mac Catalyst | 15.0 | arm64, x86_64 | — |
| tvOS | 15.0 | arm64 | arm64, x86_64 |
| watchOS | 8.0 | arm64 (26.0+), arm64_32, armv7k | arm64, x86_64 |
| visionOS | 1.0 | arm64 | arm64 |

macOS, iOS, and Catalyst use prebuilt standard libraries from pinned stable
Rust. The remaining targets use the pinned nightly compiler with
`-Zbuild-std`; this also supplies x86_64 and older watchOS targets that Rust does
not distribute as prebuilt components. Rust defines the newer watch device
`arm64` target with a watchOS 26 floor; watchOS 8–25 devices use the included
`arm64_32` or `armv7k` slices.

The feature set augments the C ABI crate's defaults and its
`loader,custom_syntax,fuel` dependency features with `unicode`, `json`,
`urlencode`, `speedups`, and `loop_controls`. Features are enabled through
Cargo's command line; upstream manifests are never patched.

## Verification

`just verify` checks more than module-map syntax:

1. every thin archive has its declared architecture;
2. all 68 expected C ABI functions are exported by every architecture;
3. Clang imports the module for every target triple and SDK;
4. Swift imports raw functions and `MJ_*` enum constants for every configured
   target triple, including arm64_32 and armv7k watchOS devices;
5. a host Swift executable links the static library and renders a template;
6. `MiniJinjaEvaluation` consumes the completed XCFramework as a local SwiftPM
   binary target.

The symbol manifest intentionally makes an upstream ABI change fail loudly.
Update `config/required-symbols.txt`, smoke tests, and the Swift wrapper together
when the C header changes.

## Packaging and provenance

`just package` normalizes archive timestamps to the source commit time and uses
a metadata-free, sorted zip input. XCFramework creation also canonicalizes
`AvailableLibraries` by `LibraryIdentifier`, removing nondeterministic array
ordering from Xcode's generated `Info.plist`. On the same Xcode/Rust environment
this makes the package reproducible. The `output` directory contains:

- `MiniJinjaC.xcframework.zip`
- SHA-256 and SwiftPM checksum files plus `MiniJinjaC.checksums.json`
- `MiniJinjaC.build-info.json` with source, toolchain, feature, SDK, deployment,
  and architecture data
- the exact dependency graph in `MiniJinjaC.Cargo.lock`

The XCFramework itself embeds redistribution notices under `Licenses/`; they
are therefore present for direct downloads and SwiftPM consumers rather than
only on the GitHub release page.

Release CI additionally creates an SPDX JSON SBOM and GitHub artifact
attestations for both build provenance and the SBOM. With GitHub CLI installed,
a downloaded release can be verified using:

```sh
gh attestation verify MiniJinjaC.xcframework.zip \
  --repo plx/minijinja-xcframework
shasum -a 256 -c MiniJinjaC.xcframework.zip.sha256
```

Source tags and binary-artifact tags have independent namespaces. Releases use
`minijinja-<source-version>-<artifact-revision>`; the first 2.24.0 artifact is
therefore `minijinja-2.24.0-1`, while the canonicalized artifact is revision 2.
This leaves historical `v<source-version>` tags untouched and permits a new
artifact revision without moving a published tag.
The workflow refuses to publish through an existing tag unless that tag points
at the exact pipeline commit being run; select the next artifact revision when
the pipeline changes.

The scheduled release workflow checks upstream daily and only builds when the
latest upstream artifact revision is absent here. Artifact-tag pushes and manual
dispatches use the same build, verification, SBOM, attestation, and release
path. All third-party GitHub Actions are pinned to full commit SHAs.
