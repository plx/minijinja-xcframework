# minijinja XCFramework Build System
# ====================================

# Constants
# ---------

# Version (can be overridden via environment variable or command line)
MINIJINJA_VERSION := env_var_or_default('MINIJINJA_VERSION', 'main')

# Directory paths
ROOT_DIR := justfile_directory()
BUILD_DIR := ROOT_DIR / "build"
OUTPUT_DIR := ROOT_DIR / "output"
MINIJINJA_DIR := BUILD_DIR / "minijinja"
CAPI_DIR := MINIJINJA_DIR / "minijinja-capi"
PLATFORMS_DIR := BUILD_DIR / "platforms"

# Deployment targets
MINIMUM_DEPLOYMENT_TARGET := "26.0"

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
VISIONOS_SDK := "visionos"
VISIONOS_SIM_SDK := "visionossimulator"

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

# Default recipe (shows available commands)
default:
    @just --list

# Main Build Recipe
# ==================

# Build the complete XCFramework (all steps)
build: clean clone-minijinja install-targets build-all create-fat-binaries create-xcframework package
    @echo "✅ Build complete!"

# Top-Level Build Steps
# ======================

# Clean previous builds
clean:
    @echo "🧹 Cleaning build directories..."
    rm -rf "{{BUILD_DIR}}" "{{OUTPUT_DIR}}"
    mkdir -p "{{BUILD_DIR}}" "{{OUTPUT_DIR}}"

# Clone minijinja from upstream
clone-minijinja:
    @echo "📦 Cloning minijinja..."
    #!/usr/bin/env bash
    set -e
    cd "{{BUILD_DIR}}"
    if [ "{{MINIJINJA_VERSION}}" == "main" ]; then
        git clone https://github.com/mitsuhiko/minijinja.git
    else
        git clone --branch "v{{MINIJINJA_VERSION}}" --depth 1 https://github.com/mitsuhiko/minijinja.git
    fi

# Install all Rust cross-compilation targets
install-targets:
    @echo "🎯 Installing Rust targets..."
    rustup target add \
        {{IOS_DEVICE_TARGET}} \
        {{IOS_SIM_X86_TARGET}} \
        {{IOS_SIM_ARM_TARGET}} \
        {{CATALYST_ARM_TARGET}} \
        {{CATALYST_X86_TARGET}} \
        {{MACOS_ARM_TARGET}} \
        {{MACOS_X86_TARGET}} \
        {{TVOS_DEVICE_TARGET}} \
        {{TVOS_SIM_X86_TARGET}} \
        {{TVOS_SIM_ARM_TARGET}} \
        {{WATCHOS_DEVICE_TARGET}} \
        {{WATCHOS_SIM_ARM_TARGET}} \
        {{WATCHOS_SIM_X86_TARGET}} \
        {{VISIONOS_DEVICE_TARGET}} \
        {{VISIONOS_SIM_TARGET}}

# Build all platform targets
build-all: build-ios build-catalyst build-macos build-tvos build-watchos build-visionos
    @echo "✅ All targets built"

# Create all universal (fat) binaries
create-fat-binaries: create-ios-sim-fat create-macos-fat create-catalyst-fat create-tvos-sim-fat create-watchos-sim-fat
    @echo "✅ All fat binaries created"

# Create the XCFramework
create-xcframework:
    @echo "📱 Creating XCFramework..."
    xcodebuild -create-xcframework \
        -library "{{PLATFORMS_DIR}}/{{IOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{IOS_DEVICE}}-{{ARM64}}/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{IOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{IOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{IOS_SIMULATOR}}-universal/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{IOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{MACOS}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{MACOS}}-universal/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{MACOS}}-universal/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{CATALYST}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{CATALYST}}-universal/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{CATALYST}}-universal/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{TVOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{TVOS_DEVICE}}-{{ARM64}}/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{TVOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{TVOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{TVOS_SIMULATOR}}-universal/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{TVOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{WATCHOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{WATCHOS_DEVICE}}-{{ARM64}}/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{WATCHOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{WATCHOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{WATCHOS_SIMULATOR}}-universal/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{WATCHOS_SIMULATOR}}-universal/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{VISIONOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{VISIONOS_DEVICE}}-{{ARM64}}/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{VISIONOS_DEVICE}}-{{ARM64}}/lib/{{LIBRARY_NAME}}.dSYM" \
        -library "{{PLATFORMS_DIR}}/{{VISIONOS_SIMULATOR}}-{{ARM64}}/lib/{{LIBRARY_NAME}}" \
        -headers "{{PLATFORMS_DIR}}/{{VISIONOS_SIMULATOR}}-{{ARM64}}/include" \
        -debug-symbols "{{PLATFORMS_DIR}}/{{VISIONOS_SIMULATOR}}-{{ARM64}}/lib/{{LIBRARY_NAME}}.dSYM" \
        -output "{{OUTPUT_DIR}}/minijinja.xcframework"

# Package XCFramework and compute checksum
package:
    @echo "📦 Creating distribution zip..."
    #!/usr/bin/env bash
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
build-ios: (build-target IOS_DEVICE_TARGET IOS_DEVICE IOS_SDK ARM64) \
           (build-target IOS_SIM_X86_TARGET IOS_SIMULATOR IOS_SIM_SDK X86_64) \
           (build-target IOS_SIM_ARM_TARGET IOS_SIMULATOR IOS_SIM_SDK ARM64)
    @echo "✅ iOS targets built"

# Build all Catalyst targets
build-catalyst: (build-target CATALYST_ARM_TARGET CATALYST MACOS_SDK ARM64) \
                (build-target CATALYST_X86_TARGET CATALYST MACOS_SDK X86_64)
    @echo "✅ Catalyst targets built"

# Build all macOS targets
build-macos: (build-target MACOS_ARM_TARGET MACOS MACOS_SDK ARM64) \
             (build-target MACOS_X86_TARGET MACOS MACOS_SDK X86_64)
    @echo "✅ macOS targets built"

# Build all tvOS targets
build-tvos: (build-target TVOS_DEVICE_TARGET TVOS_DEVICE TVOS_SDK ARM64) \
            (build-target TVOS_SIM_X86_TARGET TVOS_SIMULATOR TVOS_SIM_SDK X86_64) \
            (build-target TVOS_SIM_ARM_TARGET TVOS_SIMULATOR TVOS_SIM_SDK ARM64)
    @echo "✅ tvOS targets built"

# Build all watchOS targets
build-watchos: (build-target WATCHOS_DEVICE_TARGET WATCHOS_DEVICE WATCHOS_SDK ARM64) \
               (build-target WATCHOS_SIM_ARM_TARGET WATCHOS_SIMULATOR WATCHOS_SIM_SDK ARM64) \
               (build-target WATCHOS_SIM_X86_TARGET WATCHOS_SIMULATOR WATCHOS_SIM_SDK X86_64)
    @echo "✅ watchOS targets built"

# Build all visionOS targets
build-visionos: (build-target VISIONOS_DEVICE_TARGET VISIONOS_DEVICE VISIONOS_SDK ARM64) \
                (build-target VISIONOS_SIM_TARGET VISIONOS_SIMULATOR VISIONOS_SIM_SDK ARM64)
    @echo "✅ visionOS targets built"

# Fat Binary Creation Commands
# =============================

# Create iOS Simulator universal binary
create-ios-sim-fat: (create-fat-binary IOS_SIMULATOR X86_64 ARM64)

# Create macOS universal binary
create-macos-fat: (create-fat-binary MACOS X86_64 ARM64)

# Create Catalyst universal binary
create-catalyst-fat: (create-fat-binary CATALYST X86_64 ARM64)

# Create tvOS Simulator universal binary
create-tvos-sim-fat: (create-fat-binary TVOS_SIMULATOR X86_64 ARM64)

# Create watchOS Simulator universal binary
create-watchos-sim-fat: (create-fat-binary WATCHOS_SIMULATOR X86_64 ARM64)

# General-Purpose Build Commands
# ===============================

# Build for a specific target (parameterized)
build-target TARGET_VAR PLATFORM_VAR SDK_VAR ARCH_VAR:
    @echo "🔨 Building for {{TARGET_VAR}}..."
    #!/usr/bin/env bash
    set -e

    # Resolve variable references
    TARGET="{{TARGET_VAR}}"
    PLATFORM="{{PLATFORM_VAR}}"
    SDK="{{SDK_VAR}}"
    ARCH="{{ARCH_VAR}}"

    # Set up build environment
    export SDKROOT=$(xcrun --sdk "$SDK" --show-sdk-path)
    export CC=$(xcrun --sdk "$SDK" --find clang)
    export CXX=$(xcrun --sdk "$SDK" --find clang++)
    export AR=$(xcrun --sdk "$SDK" --find ar)

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
    cargo build --release --target "$TARGET"

    # Create platform-specific directory
    PLATFORM_DIR="{{PLATFORMS_DIR}}/${PLATFORM}-${ARCH}"
    mkdir -p "$PLATFORM_DIR/include" "$PLATFORM_DIR/lib"

    # Copy headers and library
    cp "{{CAPI_DIR}}/include/{{HEADER_NAME}}" "$PLATFORM_DIR/include/"
    cp "{{MINIJINJA_DIR}}/target/$TARGET/release/libminijinja_capi.a" "$PLATFORM_DIR/lib/{{LIBRARY_NAME}}"

    # Extract debug symbols
    echo "  📝 Extracting debug symbols..."
    dsymutil "$PLATFORM_DIR/lib/{{LIBRARY_NAME}}" -o "$PLATFORM_DIR/lib/{{LIBRARY_NAME}}.dSYM"

# Create a universal (fat) binary for a platform
create-fat-binary PLATFORM_VAR ARCH1_VAR ARCH2_VAR:
    @echo "🔗 Creating {{PLATFORM_VAR}} universal binary..."
    #!/usr/bin/env bash
    set -e

    PLATFORM="{{PLATFORM_VAR}}"
    ARCH1="{{ARCH1_VAR}}"
    ARCH2="{{ARCH2_VAR}}"

    cd "{{PLATFORMS_DIR}}"

    # Create universal directory
    mkdir -p "${PLATFORM}-universal/lib"

    # Create fat binary
    lipo -create \
        "${PLATFORM}-${ARCH1}/lib/{{LIBRARY_NAME}}" \
        "${PLATFORM}-${ARCH2}/lib/{{LIBRARY_NAME}}" \
        -output "${PLATFORM}-universal/lib/{{LIBRARY_NAME}}"

    # Copy headers
    cp -r "${PLATFORM}-${ARCH2}/include" "${PLATFORM}-universal/"

    # Merge dSYMs
    mkdir -p "${PLATFORM}-universal/lib/{{LIBRARY_NAME}}.dSYM/Contents/Resources/DWARF"
    lipo -create \
        "${PLATFORM}-${ARCH1}/lib/{{LIBRARY_NAME}}.dSYM/Contents/Resources/DWARF/{{LIBRARY_NAME}}" \
        "${PLATFORM}-${ARCH2}/lib/{{LIBRARY_NAME}}.dSYM/Contents/Resources/DWARF/{{LIBRARY_NAME}}" \
        -output "${PLATFORM}-universal/lib/{{LIBRARY_NAME}}.dSYM/Contents/Resources/DWARF/{{LIBRARY_NAME}}"
    cp "${PLATFORM}-${ARCH2}/lib/{{LIBRARY_NAME}}.dSYM/Contents/Info.plist" \
       "${PLATFORM}-universal/lib/{{LIBRARY_NAME}}.dSYM/Contents/"
