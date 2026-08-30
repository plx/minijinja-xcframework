#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

assert_generated_path "$BUILD_DIR"
assert_generated_path "$OUTPUT_DIR"

log "Removing generated build and output directories"
rm -rf -- "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
