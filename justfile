set shell := ["bash", "-euo", "pipefail", "-c"]

# Build a release-ready XCFramework from the pinned MiniJinja source.
[group('build')]
build:
    ./scripts/clean.sh
    ./scripts/bootstrap.sh
    ./scripts/prepare-source.sh
    ./scripts/build-slices.sh all
    ./scripts/create-xcframework.sh
    ./scripts/verify.sh
    ./scripts/package.sh

# Rebuild from an already-prepared source checkout.
[group('build')]
rebuild:
    ./scripts/bootstrap.sh
    ./scripts/build-slices.sh all
    ./scripts/create-xcframework.sh
    ./scripts/verify.sh
    ./scripts/package.sh

# Remove generated build and output directories.
[group('build')]
clean:
    ./scripts/clean.sh

# Install the exact Rust toolchains and prebuilt cross-compilation targets.
[group('setup')]
bootstrap:
    ./scripts/bootstrap.sh

# Fetch and verify the configured MiniJinja source revision.
[group('setup')]
prepare:
    ./scripts/prepare-source.sh

# Build every configured architecture without creating the XCFramework.
[group('build')]
build-slices selector="all":
    ./scripts/build-slices.sh "{{ selector }}"

# Merge architecture slices and create MiniJinjaC.xcframework.
[group('build')]
create-xcframework:
    ./scripts/create-xcframework.sh

# Verify architectures, exported ABI, Clang/Swift imports, and host execution.
[group('verify')]
verify:
    ./scripts/verify.sh

# Produce a deterministic zip, checksums, Cargo.lock, and build metadata.
[group('package')]
package:
    ./scripts/package.sh

# Run static checks without building MiniJinja.
[group('verify')]
lint:
    ./scripts/lint.sh

# Exercise the module map and API notes against a synthetic C header.
[group('verify')]
test-module:
    ./scripts/test-module.sh

# Print the effective source, toolchain, feature, and platform configuration.
[group('help')]
configuration:
    ./scripts/show-configuration.sh
