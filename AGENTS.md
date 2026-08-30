# Guide for Agents

This repository produces the `MiniJinjaC` binary dependency for
`hdxl-swift-minijinja`. Preserve these contracts:

- The source repository, ref, exact commit, stable Rust, and nightly Rust are
  pinned in `scripts/common.sh` and documented in `README.md`.
- `config/apple-targets.txt` is the source of truth for target triples, SDKs,
  architectures, deployment floors, and toolchain selection.
- The archive, XCFramework, SwiftPM target, and Clang module are named
  `MiniJinjaC`; the static library is `libMiniJinjaC.a`.
- Do not ship API notes. The Swift wrapper compiles against the raw Clang import,
  including `MJ_*` constants, function names, and pointer optionality.
- Do not edit the fetched MiniJinja checkout. Static library output and optional
  engine features are requested through `cargo rustc`.
- Any upstream C ABI change must update `config/required-symbols.txt`, import
  smoke tests, and the Swift wrapper together.

Run `just lint` for static checks and `just build` for the complete build,
cross-target verification, host execution test, SwiftPM test, and package.
