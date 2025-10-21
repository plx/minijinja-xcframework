#!/usr/bin/env bash
set -e

echo "🚀 Building minijinja XCFramework..."

# Configuration
MINIJINJA_VERSION="${1:-main}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/build"
OUTPUT_DIR="$ROOT_DIR/output"
MINIMUM_DEPLOYMENT_TARGET=26.0

# Clean previous builds
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

# Clone minijinja
echo "📦 Cloning minijinja..."
cd "$BUILD_DIR"
if [ "$MINIJINJA_VERSION" == "main" ]; then
    git clone https://github.com/mitsuhiko/minijinja.git
    cd minijinja
else
    git clone --branch "v$MINIJINJA_VERSION" --depth 1 https://github.com/mitsuhiko/minijinja.git
    cd minijinja
fi

# Install Rust targets
echo "🎯 Installing Rust targets..."
rustup target add \
    aarch64-apple-ios \
    x86_64-apple-ios \
    aarch64-apple-ios-sim \
    aarch64-apple-ios-macabi \
    x86_64-apple-ios-macabi \
    aarch64-apple-tvos \
    x86_64-apple-tvos \
    aarch64-apple-tvos-sim \
    aarch64-apple-watchos \
    aarch64-apple-watchos-sim \
    x86_64-apple-watchos-sim \
    aarch64-apple-darwin \
    x86_64-apple-darwin \
    aarch64-apple-visionos \
    aarch64-apple-visionos-sim 

# Function to build for a specific target
build_target() {
    local TARGET=$1
    local PLATFORM=$2
    local SDK=$3
    local ARCH=$4
    
    echo "🔨 Building for $TARGET..."
    
    export SDKROOT=$(xcrun --sdk $SDK --show-sdk-path)
    export CC=$(xcrun --sdk $SDK --find clang)
    export CXX=$(xcrun --sdk $SDK --find clang++)
    export AR=$(xcrun --sdk $SDK --find ar)
    
    # Build the C API crate
    cd "$BUILD_DIR/minijinja/minijinja-capi"
    
    export IPHONEOS_DEPLOYMENT_TARGET=26.0
    export MACOSX_DEPLOYMENT_TARGET=26.0
    export TVOS_DEPLOYMENT_TARGET=26.0
    export WATCHOS_DEPLOYMENT_TARGET=26.0
    export VISIONOS_DEPLOYMENT_TARGET=26.0

    # Build with debug symbols (even in release mode)
    export RUSTFLAGS="-C debuginfo=2"
    cargo build --release --target $TARGET
    
    # Create platform-specific directory
    local PLATFORM_DIR="$BUILD_DIR/platforms/$PLATFORM-$ARCH"
    mkdir -p "$PLATFORM_DIR/include" "$PLATFORM_DIR/lib"
    
    # Copy headers and library
    cp "$BUILD_DIR/minijinja/minijinja-capi/include/minijinja.h" "$PLATFORM_DIR/include/"
    cp "$BUILD_DIR/minijinja/target/$TARGET/release/libminijinja_capi.a" "$PLATFORM_DIR/lib/libminijinja.a"

    # Extract debug symbols
    echo "  📝 Extracting debug symbols..."
    dsymutil "$PLATFORM_DIR/lib/libminijinja.a" -o "$PLATFORM_DIR/lib/libminijinja.a.dSYM"
}

# Build for iOS
build_target "aarch64-apple-ios" "ios" "iphoneos" "arm64"
build_target "x86_64-apple-ios" "ios-simulator" "iphonesimulator" "x86_64"
build_target "aarch64-apple-ios-sim" "ios-simulator" "iphonesimulator" "arm64"

# Build for Catalyst
build_target "aarch64-apple-ios-macabi" "catalyst" "macosx" "arm64"
build_target "x86_64-apple-ios-macabi" "catalyst" "macosx" "x86_64"

# Build for macOS
build_target "aarch64-apple-darwin" "macos" "macosx" "arm64"
build_target "x86_64-apple-darwin" "macos" "macosx" "x86_64"

# Build for tvOS
build_target "aarch64-apple-tvos" "tvos" "appletvos" "arm64"
build_target "x86_64-apple-tvos" "tvos-simulator" "appletvsimulator" "x86_64"
build_target "aarch64-apple-tvos-sim" "tvos-simulator" "appletvsimulator" "arm64"

# Build for watchOS
build_target "aarch64-apple-watchos" "watchos" "watchos" "arm64"
build_target "aarch64-apple-watchos-sim" "watchos-simulator" "watchsimulator" "arm64"
build_target "x86_64-apple-watchos-sim" "watchos-simulator" "watchsimulator" "x86_64"

# Build for visionOS
build_target "aarch64-apple-visionos" "visionos" "visionos" "arm64"
build_target "aarch64-apple-visionos-sim" "visionos-simulator" "visionossimulator" "arm64"

# Create fat binaries for simulators
echo "🔗 Creating fat binaries..."
cd "$BUILD_DIR/platforms"

# iOS Simulator
mkdir -p ios-simulator-universal/lib
lipo -create ios-simulator-x86_64/lib/libminijinja.a ios-simulator-arm64/lib/libminijinja.a \
     -output ios-simulator-universal/lib/libminijinja.a
cp -r ios-simulator-arm64/include ios-simulator-universal/
# Merge dSYMs
mkdir -p ios-simulator-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF
lipo -create \
     ios-simulator-x86_64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     ios-simulator-arm64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     -output ios-simulator-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a
cp ios-simulator-arm64/lib/libminijinja.a.dSYM/Contents/Info.plist ios-simulator-universal/lib/libminijinja.a.dSYM/Contents/

# macOS
mkdir -p macos-universal/lib
lipo -create macos-x86_64/lib/libminijinja.a macos-arm64/lib/libminijinja.a \
     -output macos-universal/lib/libminijinja.a
cp -r macos-arm64/include macos-universal/
# Merge dSYMs
mkdir -p macos-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF
lipo -create \
     macos-x86_64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     macos-arm64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     -output macos-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a
cp macos-arm64/lib/libminijinja.a.dSYM/Contents/Info.plist macos-universal/lib/libminijinja.a.dSYM/Contents/

# tvOS Simulator
mkdir -p tvos-simulator-universal/lib
lipo -create tvos-simulator-x86_64/lib/libminijinja.a tvos-simulator-arm64/lib/libminijinja.a \
     -output tvos-simulator-universal/lib/libminijinja.a
cp -r tvos-simulator-arm64/include tvos-simulator-universal/
# Merge dSYMs
mkdir -p tvos-simulator-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF
lipo -create \
     tvos-simulator-x86_64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     tvos-simulator-arm64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     -output tvos-simulator-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a
cp tvos-simulator-arm64/lib/libminijinja.a.dSYM/Contents/Info.plist tvos-simulator-universal/lib/libminijinja.a.dSYM/Contents/

# watchOS Simulator
mkdir -p watchos-simulator-universal/lib
lipo -create watchos-simulator-x86_64/lib/libminijinja.a watchos-simulator-arm64/lib/libminijinja.a \
     -output watchos-simulator-universal/lib/libminijinja.a
cp -r watchos-simulator-arm64/include watchos-simulator-universal/
# Merge dSYMs
mkdir -p watchos-simulator-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF
lipo -create \
     watchos-simulator-x86_64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     watchos-simulator-arm64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     -output watchos-simulator-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a
cp watchos-simulator-arm64/lib/libminijinja.a.dSYM/Contents/Info.plist watchos-simulator-universal/lib/libminijinja.a.dSYM/Contents/

# Catalyst
mkdir -p catalyst-universal/lib
lipo -create catalyst-x86_64/lib/libminijinja.a catalyst-arm64/lib/libminijinja.a \
     -output catalyst-universal/lib/libminijinja.a
cp -r catalyst-arm64/include catalyst-universal/
# Merge dSYMs
mkdir -p catalyst-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF
lipo -create \
     catalyst-x86_64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     catalyst-arm64/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a \
     -output catalyst-universal/lib/libminijinja.a.dSYM/Contents/Resources/DWARF/libminijinja.a
cp catalyst-arm64/lib/libminijinja.a.dSYM/Contents/Info.plist catalyst-universal/lib/libminijinja.a.dSYM/Contents/

# Create XCFramework
echo "📱 Creating XCFramework..."
cd "$ROOT_DIR"

xcodebuild -create-xcframework \
    -library "$BUILD_DIR/platforms/ios-arm64/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/ios-arm64/include" \
    -debug-symbols "$BUILD_DIR/platforms/ios-arm64/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/ios-simulator-universal/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/ios-simulator-universal/include" \
    -debug-symbols "$BUILD_DIR/platforms/ios-simulator-universal/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/macos-universal/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/macos-universal/include" \
    -debug-symbols "$BUILD_DIR/platforms/macos-universal/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/catalyst-universal/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/catalyst-universal/include" \
    -debug-symbols "$BUILD_DIR/platforms/catalyst-universal/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/tvos-arm64/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/tvos-arm64/include" \
    -debug-symbols "$BUILD_DIR/platforms/tvos-arm64/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/tvos-simulator-universal/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/tvos-simulator-universal/include" \
    -debug-symbols "$BUILD_DIR/platforms/tvos-simulator-universal/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/watchos-arm64/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/watchos-arm64/include" \
    -debug-symbols "$BUILD_DIR/platforms/watchos-arm64/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/watchos-simulator-universal/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/watchos-simulator-universal/include" \
    -debug-symbols "$BUILD_DIR/platforms/watchos-simulator-universal/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/visionos-arm64/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/visionos-arm64/include" \
    -debug-symbols "$BUILD_DIR/platforms/visionos-arm64/lib/libminijinja.a.dSYM" \
    -library "$BUILD_DIR/platforms/visionos-simulator-arm64/lib/libminijinja.a" \
    -headers "$BUILD_DIR/platforms/visionos-simulator-arm64/include" \
    -debug-symbols "$BUILD_DIR/platforms/visionos-simulator-arm64/lib/libminijinja.a.dSYM" \
    -output "$OUTPUT_DIR/minijinja.xcframework"

# Create zip for distribution
echo "📦 Creating distribution zip..."
cd "$OUTPUT_DIR"
zip -r minijinja.xcframework.zip minijinja.xcframework

# Calculate checksum
CHECKSUM=$(swift package compute-checksum minijinja.xcframework.zip)
echo "✅ XCFramework built successfully!"
echo "📝 Checksum: $CHECKSUM"
echo "📍 Output: $OUTPUT_DIR/minijinja.xcframework.zip"
