# minijinja-xcframework

This repository contains a justfile "build script" that will clone-and-build [minijinja](https://github.com/mitsuhiko/minijinja) as an XCFramework, suitable for use in Swift Package Manager.

It also contains Github Actions workflows to automatically build and publish new releases whenever a new minijinja version is released.

This repository exists to facilitate development of its sister project, [hdxl-swift-minijinja](https://github.com/plx/hdxl-swift-minijinja), but the justfile build system may be useful for others as well.

## Prerequisites

- macOS 26.0+ with Xcode installed
- Rustup installed
- [just](https://github.com/casey/just) command runner

## Building

### Build Everything

To build the complete XCFramework:

```bash
just build
```

By default, this will build `minijinja` from `main`; you can override this by setting the `MINIJINJA_VERSION` environment variable to a specific release (e.g. `MINIJINJA_VERSION=2.1.0 just build` will build `minijinja`'s 2.1.0 release).

### Platforms and Rust Tiers

The XCFramework is built for the following Apple platforms:

- macOS (tier 1)
- iOS (tier 2)
- Mac Catalyst (tier 2)
- tvOS (tier 3)
- watchOS (tier 3)
- visionOS (tier 3)

The "tiers" refer to the platform's status in the Rust ecosystem; [per the rustc book[^1]](https://doc.rust-lang.org/rustc/target-tier-policy.html):

> Rust's continuous integration checks that tier 1 targets will always build and pass tests.
> 
> Rust's continuous integration checks that tier 2 targets will always build, but they may or may not pass tests.
> 
> Rust provides no guarantees about tier 3 targets; they exist in the codebase, but may or may not build.

[^1]: Quoted exactly, but reordered for clarity.

As such, please take note that `minijinja-xcframework`, itself, inherits those guarantees on a platform-by-platform basis.

### Module Verification

The build process includes automatic Clang module verification to ensure proper modularization:

- A `module.modulemap` file is included with each platform build
- After building and creating fat binaries, the build system runs `just verify-modules`
- Verification uses Clang's `-fmodules` and `-fmodules-validate-system-headers` flags
- Each platform's module is tested by attempting to import it in a test Objective-C file

You can run module verification separately:

```bash
# Verify all modules (after building)
just verify-modules

# Verify specific platform modules
just verify-ios-modules
just verify-macos-modules
just verify-catalyst-modules
just verify-tvos-modules
just verify-watchos-modules
just verify-visionos-modules
```

This ensures that the headers are properly modularized and can be imported from Swift and Objective-C code.

### Future Directions

*Eventually* this repository may gain a "local" Swift package that:

- imports the framework as a module
- runs a suite of basic unit tests against it

Until then, users of `minijinja-xcframework` should take care to prepare their own test suites to ensure proper functionality.
