# minijinja XCFramework Build System
# ====================================

# Constants
# ---------

# Version (can be overridden via environment variable or command line)
MINIJINJA_VERSION := env_var_or_default('MINIJINJA_VERSION', 'main')

# Toolchain versions
STABLE_TOOLCHAIN := env_var_or_default('MINIJINJA_STABLE_TOOLCHAIN', '1.90.0')

# TODO: Pin to specific date after testing
NIGHTLY_TOOLCHAIN := env_var_or_default('MINIJINJA_NIGHTLY_TOOLCHAIN', 'nightly')

# Directory paths
ROOT_DIR := justfile_directory()
BUILD_DIR := ROOT_DIR / "build"
OUTPUT_DIR := ROOT_DIR / "output"
MINIJINJA_DIR := BUILD_DIR / "minijinja"
CAPI_DIR := MINIJINJA_DIR / "minijinja-cabi"
PLATFORMS_DIR := BUILD_DIR / "platforms"

# Deployment targets
MINIMUM_DEPLOYMENT_TARGET := env_var_or_default('MINIJINJA_MINIMUM_DEPLOYMENT_TARGET', '26.0')

# Rust targets
IOS_DEVICE_TARGET := "aarch64-apple-ios"
IOS_SIM_X86_TARGET := "x86_64-apple-ios"
IOS_SIM_ARM_TARGET := "aarch64-apple-ios-sim"

CATALYST_ARM_TARGET := "aarch64-apple-ios-macabi"
CATALYST_X86_TARGET := "x86_64-apple-ios-macabi"

MACOS_ARM_TARGET := "aarch64-apple-darwin"
MACOS_X86_TARGET := "x86_64-apple-darwin"

TVOS_DEVICE_TARGET := "aarch64-apple-tvos"
TVOS_SIM_X86_TARGET := "x86_64-apple-tvos"
TVOS_SIM_ARM_TARGET := "aarch64-apple-tvos-sim"

WATCHOS_DEVICE_TARGET := "aarch64-apple-watchos"
WATCHOS_SIM_ARM_TARGET := "aarch64-apple-watchos-sim"
WATCHOS_SIM_X86_TARGET := "x86_64-apple-watchos-sim"

VISIONOS_DEVICE_TARGET := "aarch64-apple-visionos"
VISIONOS_SIM_TARGET := "aarch64-apple-visionos-sim"

# SDK names
IOS_SDK := "iphoneos"
IOS_SIM_SDK := "iphonesimulator"
MACOS_SDK := "macosx"
TVOS_SDK := "appletvos"
TVOS_SIM_SDK := "appletvsimulator"
WATCHOS_SDK := "watchos"
WATCHOS_SIM_SDK := "watchsimulator"
# NOTE: `xcodebuild` still uses `xros` and `xrsimulator` instead of `visionOS` (etc.)
VISIONOS_SDK := "xros"
VISIONOS_SIM_SDK := "xrsimulator"

# Architecture names
ARM64 := "arm64"
X86_64 := "x86_64"

# Platform identifiers
IOS_DEVICE := "ios"
IOS_SIMULATOR := "ios-simulator"
CATALYST := "catalyst"
MACOS := "macos"
TVOS_DEVICE := "tvos"
TVOS_SIMULATOR := "tvos-simulator"
WATCHOS_DEVICE := "watchos"
WATCHOS_SIMULATOR := "watchos-simulator"
VISIONOS_DEVICE := "visionos"
VISIONOS_SIMULATOR := "visionos-simulator"

# Library and header names
LIBRARY_NAME := "libminijinja.a"
HEADER_NAME := "minijinja.h"
MODULEMAP_NAME := "module.modulemap"

# Default recipe (shows available commands)
default:
    @just --list

# Main Build Recipe
# ==================

# Build the complete XCFramework (all steps)
[group('build')]
build: clean clone-minijinja install-targets build-all create-fat-binaries verify-modules create-xcframework package
    @echo "✅ Build complete!"

# Top-Level Build Steps
# ======================

# Install Rust toolchains required for building
[group('install')]
install-toolchains:
    @echo "🦀 Installing Rust toolchains..."
    rustup toolchain install {{STABLE_TOOLCHAIN}}
    rustup toolchain install {{NIGHTLY_TOOLCHAIN}}
    rustup component add rust-src --toolchain {{NIGHTLY_TOOLCHAIN}}
    @echo "✅ Toolchains installed"

# Clean previous builds
[group('build')]
clean:
    @echo "🧹 Cleaning build directories..."
    rm -rf "{{BUILD_DIR}}" "{{OUTPUT_DIR}}"
    mkdir -p "{{BUILD_DIR}}" "{{OUTPUT_DIR}}"

# Clone minijinja from upstream
[group('build')]
clone-minijinja version=MINIJINJA_VERSION: clean
    #!/usr/bin/env bash
    echo "📦 Cloning minijinja @ {{version}}..."
    set -e
    cd "{{BUILD_DIR}}"
    if [ "{{version}}" == "main" ]; then
        git clone https://github.com/mitsuhiko/minijinja.git
    else
        git clone --branch "v{{version}}" --depth 1 https://github.com/mitsuhiko/minijinja.git
    fi

    # Patch minijinja-cabi to build as staticlib instead of cdylib for XCFramework
    echo "🔧 Patching minijinja-cabi for static library build..."
    cd "{{CAPI_DIR}}"
    sed -i '' 's/crate-type = \["cdylib"\]/crate-type = ["staticlib"]/' Cargo.toml

# Install all Rust cross-compilation targets (hierarchical)
[group('install')]
install-targets: install-toolchains install-ios-targets install-catalyst-targets install-macos-targets
    @echo "✅ All targets installed"
    @echo "ℹ️  Note: tvOS, watchOS, and visionOS are tier 3 targets and will be built using -Zbuild-std"

# Install iOS targets (tier 2)
[group('install')]
[group('iOS')]
[group('tier-2')]
install-ios-targets:
    @echo "  📦 Installing {{IOS_DEVICE_TARGET}}..."
    @rustup target add {{IOS_DEVICE_TARGET}} --toolchain {{STABLE_TOOLCHAIN}}
    @echo "  📦 Installing {{IOS_SIM_X86_TARGET}}..."
    @rustup target add {{IOS_SIM_X86_TARGET}} --toolchain {{STABLE_TOOLCHAIN}}
    @echo "  📦 Installing {{IOS_SIM_ARM_TARGET}}..."
    @rustup target add {{IOS_SIM_ARM_TARGET}} --toolchain {{STABLE_TOOLCHAIN}}
    @echo "✅ iOS targets installed"

# Install Catalyst targets (tier 2)
[group('install')]
[group('catalyst')]
[group('tier-2')]
install-catalyst-targets:
    @echo "  📦 Installing {{CATALYST_ARM_TARGET}}..."
    @rustup target add {{CATALYST_ARM_TARGET}} --toolchain {{STABLE_TOOLCHAIN}}
    @echo "  📦 Installing {{CATALYST_X86_TARGET}}..."
    @rustup target add {{CATALYST_X86_TARGET}} --toolchain {{STABLE_TOOLCHAIN}}
    @echo "✅ Catalyst targets installed"

# Install macOS targets (tier 1)
[group('install')]
[group('macOS')]
[group('tier-1')]
install-macos-targets:
    @echo "  📦 Installing {{MACOS_ARM_TARGET}}..."
    @rustup target add {{MACOS_ARM_TARGET}} --toolchain {{STABLE_TOOLCHAIN}}
    @echo "  📦 Installing {{MACOS_X86_TARGET}}..."
    @rustup target add {{MACOS_X86_TARGET}} --toolchain {{STABLE_TOOLCHAIN}}
    @echo "✅ macOS targets installed"

# Build all platform targets
[group('build')]
build-all: build-ios build-catalyst build-macos build-tvos build-watchos build-visionos
    @echo "✅ All targets built"

# Create all universal (fat) binaries
[group('lipo')]
create-fat-binaries: create-ios-sim-fat create-macos-fat create-catalyst-fat create-tvos-sim-fat create-watchos-sim-fat
    @echo "✅ All fat binaries created"

# Verify all platform modules
[group('verify')]
verify-modules: verify-ios-modules verify-catalyst-modules verify-macos-modules verify-tvos-modules verify-watchos-modules verify-visionos-modules
    @echo "✅ All modules verified"

# Create the XCFramework
[group('package')]
create-xcframework:
    @echo "📱 Creating XCFramework..."
    xcodebuild -create-xcframework \
        -library "{{PLATFORMS_DIR}}/{{IOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{IOS_DEVICE}}-{{ARM64}}/include" \
        -library "{{PLATFORMS_DIR}}/{{IOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{IOS_SIMULATOR}}-universal/include" \
        -library "{{PLATFORMS_DIR}}/{{MACOS}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{MACOS}}-universal/include" \
        -library "{{PLATFORMS_DIR}}/{{CATALYST}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{CATALYST}}-universal/include" \
        -library "{{PLATFORMS_DIR}}/{{TVOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{TVOS_DEVICE}}-{{ARM64}}/include" \
        -library "{{PLATFORMS_DIR}}/{{TVOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{TVOS_SIMULATOR}}-universal/include" \
        -library "{{PLATFORMS_DIR}}/{{WATCHOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{WATCHOS_DEVICE}}-{{ARM64}}/include" \
        -library "{{PLATFORMS_DIR}}/{{WATCHOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{WATCHOS_SIMULATOR}}-universal/include" \
        -library "{{PLATFORMS_DIR}}/{{VISIONOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{VISIONOS_DEVICE}}-{{ARM64}}/include" \
        -library "{{PLATFORMS_DIR}}/{{VISIONOS_SIMULATOR}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{VISIONOS_SIMULATOR}}-{{ARM64}}/include" \
        -output "{{OUTPUT_DIR}}/minijinja.xcframework"

# Package XCFramework and compute checksum
[group('package')]
package:
    #!/usr/bin/env bash
    echo "📦 Creating distribution zip..."
    set -e
    cd "{{OUTPUT_DIR}}"
    zip -r minijinja.xcframework.zip minijinja.xcframework
    CHECKSUM=$(swift package compute-checksum minijinja.xcframework.zip)
    echo "✅ XCFramework packaged successfully!"
    echo "📝 Checksum: $CHECKSUM"
    echo "📍 Output: {{OUTPUT_DIR}}/minijinja.xcframework.zip"

# Platform-Specific Build Commands
# =================================

# Build all iOS targets
[group('build')]
[group('iOS')]
[group('tier-2')]
build-ios:
    @just _build-tier2 {{IOS_DEVICE_TARGET}} {{IOS_DEVICE}} {{IOS_SDK}} {{ARM64}}
    @just _build-tier2 {{IOS_SIM_X86_TARGET}} {{IOS_SIMULATOR}} {{IOS_SIM_SDK}} {{X86_64}}
    @just _build-tier2 {{IOS_SIM_ARM_TARGET}} {{IOS_SIMULATOR}} {{IOS_SIM_SDK}} {{ARM64}}
    @echo "✅ iOS targets built"

# Build all Catalyst targets
[group('build')]
[group('catalyst')]
[group('tier-2')]
build-catalyst:
    @just _build-tier2 {{CATALYST_ARM_TARGET}} {{CATALYST}} {{MACOS_SDK}} {{ARM64}}
    @just _build-tier2 {{CATALYST_X86_TARGET}} {{CATALYST}} {{MACOS_SDK}} {{X86_64}}
    @echo "✅ Catalyst targets built"

# Build all macOS targets
[group('build')]
[group('macOS')]
[group('tier-1')]
build-macos:
    @just _build-tier2 {{MACOS_ARM_TARGET}} {{MACOS}} {{MACOS_SDK}} {{ARM64}}
    @just _build-tier2 {{MACOS_X86_TARGET}} {{MACOS}} {{MACOS_SDK}} {{X86_64}}
    @echo "✅ macOS targets built"

# Build all tvOS targets
[group('build')]
[group('tvOS')]
[group('tier-3')]
build-tvos:
    @just _build-tier3 {{TVOS_DEVICE_TARGET}} {{TVOS_DEVICE}} {{TVOS_SDK}} {{ARM64}}
    @just _build-tier3 {{TVOS_SIM_X86_TARGET}} {{TVOS_SIMULATOR}} {{TVOS_SIM_SDK}} {{X86_64}}
    @just _build-tier3 {{TVOS_SIM_ARM_TARGET}} {{TVOS_SIMULATOR}} {{TVOS_SIM_SDK}} {{ARM64}}
    @echo "✅ tvOS targets built"

# Build all watchOS targets
[group('build')]
[group('watchOS')]
[group('tier-3')]
build-watchos:
    @just _build-tier3 {{WATCHOS_DEVICE_TARGET}} {{WATCHOS_DEVICE}} {{WATCHOS_SDK}} {{ARM64}}
    @just _build-tier3 {{WATCHOS_SIM_ARM_TARGET}} {{WATCHOS_SIMULATOR}} {{WATCHOS_SIM_SDK}} {{ARM64}}
    @just _build-tier3 {{WATCHOS_SIM_X86_TARGET}} {{WATCHOS_SIMULATOR}} {{WATCHOS_SIM_SDK}} {{X86_64}}
    @echo "✅ watchOS targets built"

# Build all visionOS targets
[group('build')]
[group('visionOS')]
[group('tier-3')]
build-visionos:
    @just _build-tier3 {{VISIONOS_DEVICE_TARGET}} {{VISIONOS_DEVICE}} {{VISIONOS_SDK}} {{ARM64}}
    @just _build-tier3 {{VISIONOS_SIM_TARGET}} {{VISIONOS_SIMULATOR}} {{VISIONOS_SIM_SDK}} {{ARM64}}
    @echo "✅ visionOS targets built"

# Fat Binary Creation Commands
# =============================

# Create iOS Simulator universal binary
[group('lipo')]
[group('iOS')]
[group('tier-2')]
create-ios-sim-fat:
    @just _create-fat-binary {{IOS_SIMULATOR}} {{X86_64}} {{ARM64}}

# Create macOS universal binary
[group('lipo')]
[group('macOS')]
[group('tier-1')]
create-macos-fat:
    @just _create-fat-binary {{MACOS}} {{X86_64}} {{ARM64}}

# Create Catalyst universal binary
[group('lipo')]
[group('catalyst')]
[group('tier-2')]
create-catalyst-fat:
    @just _create-fat-binary {{CATALYST}} {{X86_64}} {{ARM64}}

# Create tvOS Simulator universal binary
[group('lipo')]
[group('tvOS')]
[group('tier-3')]
create-tvos-sim-fat:
    @just _create-fat-binary {{TVOS_SIMULATOR}} {{X86_64}} {{ARM64}}

# Create watchOS Simulator universal binary
[group('lipo')]
[group('watchOS')]
[group('tier-3')]
create-watchos-sim-fat:
    @just _create-fat-binary {{WATCHOS_SIMULATOR}} {{X86_64}} {{ARM64}}

# Module Verification Commands
# =============================

# Verify iOS modules
[group('verify')]
[group('iOS')]
verify-ios-modules:
    @just _verify-module {{IOS_DEVICE}} {{ARM64}} {{IOS_SDK}}
    @just _verify-module {{IOS_SIMULATOR}} universal {{IOS_SIM_SDK}}
    @echo "✅ iOS modules verified"

# Verify Catalyst modules
[group('verify')]
[group('catalyst')]
verify-catalyst-modules:
    @just _verify-module {{CATALYST}} universal {{MACOS_SDK}}
    @echo "✅ Catalyst modules verified"

# Verify macOS modules
[group('verify')]
[group('macOS')]
verify-macos-modules:
    @just _verify-module {{MACOS}} universal {{MACOS_SDK}}
    @echo "✅ macOS modules verified"

# Verify tvOS modules
[group('verify')]
[group('tvOS')]
verify-tvos-modules:
    @just _verify-module {{TVOS_DEVICE}} {{ARM64}} {{TVOS_SDK}}
    @just _verify-module {{TVOS_SIMULATOR}} universal {{TVOS_SIM_SDK}}
    @echo "✅ tvOS modules verified"

# Verify watchOS modules
[group('verify')]
[group('watchOS')]
verify-watchos-modules:
    @just _verify-module {{WATCHOS_DEVICE}} {{ARM64}} {{WATCHOS_SDK}}
    @just _verify-module {{WATCHOS_SIMULATOR}} universal {{WATCHOS_SIM_SDK}}
    @echo "✅ watchOS modules verified"

# Verify visionOS modules
[group('verify')]
[group('visionOS')]
verify-visionos-modules:
    @just _verify-module {{VISIONOS_DEVICE}} {{ARM64}} {{VISIONOS_SDK}}
    @just _verify-module {{VISIONOS_SIMULATOR}} {{ARM64}} {{VISIONOS_SIM_SDK}}
    @echo "✅ visionOS modules verified"

# Internal Build Implementations
# ===============================

# Build a tier 2 target (iOS, Catalyst, macOS) using stable toolchain
[group('tier-2')]
_build-tier2 TARGET PLATFORM SDK ARCH:
    #!/usr/bin/env bash
    echo "🔨 Building for {{TARGET}} (+{{STABLE_TOOLCHAIN}})..."
    set -e

    # Set up build environment
    export SDKROOT=$(xcrun --sdk "{{SDK}}" --show-sdk-path)
    export CC=$(xcrun --sdk "{{SDK}}" --find clang)
    export CXX=$(xcrun --sdk "{{SDK}}" --find clang++)
    export AR=$(xcrun --sdk "{{SDK}}" --find ar)

    # Set deployment targets
    export IPHONEOS_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}
    export MACOSX_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}
    export TVOS_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}
    export WATCHOS_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}
    export VISIONOS_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}

    # Enable debug symbols
    export RUSTFLAGS="-C debuginfo=2"

    # Build the C API crate
    cd "{{CAPI_DIR}}"
    cargo +{{STABLE_TOOLCHAIN}} build --release --target "{{TARGET}}"

    # Create platform-specific directory
    PLATFORM_DIR="{{PLATFORMS_DIR}}/{{PLATFORM}}-{{ARCH}}"
    mkdir -p "$PLATFORM_DIR/include" "$PLATFORM_DIR/lib"

    # Copy headers, module map, and library
    cp "{{CAPI_DIR}}/include/{{HEADER_NAME}}" "$PLATFORM_DIR/include/"
    cp "{{ROOT_DIR}}/{{MODULEMAP_NAME}}" "$PLATFORM_DIR/include/"
    cp "{{MINIJINJA_DIR}}/target/{{TARGET}}/release/libminijinja_cabi.a" "$PLATFORM_DIR/lib/{{LIBRARY_NAME}}"

    # Note: Debug symbols are embedded in the static library (.a file)
    # No need to extract separate dSYM for static libraries

# Build a tier 3 target (tvOS, watchOS, visionOS) using nightly toolchain with -Zbuild-std
[group('tier-3')]
_build-tier3 TARGET PLATFORM SDK ARCH:
    #!/usr/bin/env bash
    echo "🔨 Building for {{TARGET}} (+{{NIGHTLY_TOOLCHAIN}})..."
    set -e

    # Set up build environment
    export SDKROOT=$(xcrun --sdk "{{SDK}}" --show-sdk-path)
    export CC=$(xcrun --sdk "{{SDK}}" --find clang)
    export CXX=$(xcrun --sdk "{{SDK}}" --find clang++)
    export AR=$(xcrun --sdk "{{SDK}}" --find ar)

    # Set deployment targets
    export IPHONEOS_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}
    export MACOSX_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}
    export TVOS_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}
    export WATCHOS_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}
    export VISIONOS_DEPLOYMENT_TARGET={{MINIMUM_DEPLOYMENT_TARGET}}

    # Enable debug symbols
    export RUSTFLAGS="-C debuginfo=2"

    # Build the C API crate
    cd "{{CAPI_DIR}}"
    cargo +{{NIGHTLY_TOOLCHAIN}} build --release --target "{{TARGET}}" -Zbuild-std

    # Create platform-specific directory
    PLATFORM_DIR="{{PLATFORMS_DIR}}/{{PLATFORM}}-{{ARCH}}"
    mkdir -p "$PLATFORM_DIR/include" "$PLATFORM_DIR/lib"

    # Copy headers, module map, and library
    cp "{{CAPI_DIR}}/include/{{HEADER_NAME}}" "$PLATFORM_DIR/include/"
    cp "{{ROOT_DIR}}/{{MODULEMAP_NAME}}" "$PLATFORM_DIR/include/"
    cp "{{MINIJINJA_DIR}}/target/{{TARGET}}/release/libminijinja_cabi.a" "$PLATFORM_DIR/lib/{{LIBRARY_NAME}}"

    # Note: Debug symbols are embedded in the static library (.a file)
    # No need to extract separate dSYM for static libraries

# Create a universal (fat) binary for a platform
[group('lipo')]
_create-fat-binary PLATFORM ARCH1 ARCH2:
    #!/usr/bin/env bash
    echo "🔗 Creating {{PLATFORM}} universal binary..."
    set -e

    cd "{{PLATFORMS_DIR}}"

    # Create universal directory
    mkdir -p "{{PLATFORM}}-universal/lib"

    # Create fat binary
    lipo -create \
        "{{PLATFORM}}-{{ARCH1}}/lib/{{LIBRARY_NAME}}" \
        "{{PLATFORM}}-{{ARCH2}}/lib/{{LIBRARY_NAME}}" \
        -output "{{PLATFORM}}-universal/lib/{{LIBRARY_NAME}}"

    # Copy headers and module map
    cp -r "{{PLATFORM}}-{{ARCH2}}/include" "{{PLATFORM}}-universal/"

    # Note: Debug symbols are embedded in the static library
    # No separate dSYM merging needed

# Verify a module using clang
[group('verify')]
_verify-module PLATFORM ARCH SDK:
    #!/usr/bin/env bash
    echo "🔍 Verifying {{PLATFORM}}-{{ARCH}} module..."
    set -e

    # Set up SDK environment
    export SDKROOT=$(xcrun --sdk "{{SDK}}" --show-sdk-path)

    PLATFORM_DIR="{{PLATFORMS_DIR}}/{{PLATFORM}}-{{ARCH}}"
    INCLUDE_DIR="$PLATFORM_DIR/include"

    # Check that module.modulemap exists
    if [ ! -f "$INCLUDE_DIR/{{MODULEMAP_NAME}}" ]; then
        echo "❌ Error: module.modulemap not found in $INCLUDE_DIR"
        exit 1
    fi

    # Create a temporary test file to verify module import
    TEST_FILE=$(mktemp /tmp/test_module.XXXXXX.m)
    trap "rm -f $TEST_FILE" EXIT

    cat > "$TEST_FILE" << 'EOF'
    @import MiniJinjaC;

    int main() {
        // Simple test to ensure the module can be imported
        // and basic types are accessible
        mj_value val;
        return 0;
    }
    EOF

    # Verify module with clang
    # -fmodules: Enable modules
    # -fmodules-validate-system-headers: Validate system headers in modules
    # -I: Add include path
    # -fsyntax-only: Only check syntax, don't compile
    xcrun --sdk "{{SDK}}" clang \
        -fmodules \
        -fmodules-validate-system-headers \
        -I "$INCLUDE_DIR" \
        -fsyntax-only \
        "$TEST_FILE"

    if [ $? -eq 0 ]; then
        echo "✅ Module verified successfully"
    else
        echo "❌ Module verification failed"
        exit 1
    fi
