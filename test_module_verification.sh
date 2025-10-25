#!/usr/bin/env bash
# Test script for module verification
# This tests the module verification logic without requiring a full build

set -e

echo "🧪 Testing module verification logic..."

# Create a temporary test directory structure
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "📁 Creating test directory structure..."
mkdir -p "$TEST_DIR/include"

# Copy our module.modulemap
cp module.modulemap "$TEST_DIR/include/"

# Create a minimal test header
cat > "$TEST_DIR/include/minijinja.h" << 'EOF'
/*
 * Minimal test header for module verification
 */

#ifndef _minijinja_h_included
#define _minijinja_h_included

#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

typedef enum mj_value_kind {
  MJ_VALUE_KIND_UNDEFINED,
  MJ_VALUE_KIND_NONE,
} mj_value_kind;

typedef struct mj_value {
  uint64_t _opaque[3];
} mj_value;

#endif
EOF

echo "📋 Module map contents:"
cat "$TEST_DIR/include/module.modulemap"

echo ""
echo "🔍 Testing module import with clang..."

# Create a test Objective-C file
TEST_FILE=$(mktemp /tmp/test_module.XXXXXX.m)
trap "rm -f $TEST_FILE" EXIT

cat > "$TEST_FILE" << 'EOF'
@import minijinja;

int main() {
    // Simple test to ensure the module can be imported
    mj_value val;
    return 0;
}
EOF

echo "📄 Test file contents:"
cat "$TEST_FILE"

echo ""
echo "⚙️  Running clang with modules enabled..."

# Test with macOS SDK (most likely to be available)
SDK_PATH=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || echo "")

if [ -z "$SDK_PATH" ]; then
    echo "⚠️  Warning: Cannot find macOS SDK, trying without explicit SDK..."
    CLANG_CMD="clang"
else
    echo "✓ Found SDK at: $SDK_PATH"
    CLANG_CMD="xcrun --sdk macosx clang"
fi

# Run the verification
if $CLANG_CMD \
    -fmodules \
    -fmodules-validate-system-headers \
    -I "$TEST_DIR/include" \
    -fsyntax-only \
    "$TEST_FILE" 2>&1; then
    echo ""
    echo "✅ Module verification test PASSED!"
    echo "   The module.modulemap is valid and can be imported"
    exit 0
else
    echo ""
    echo "❌ Module verification test FAILED"
    exit 1
fi
