#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# These shared constants are consumed by the scripts that source this file.
# shellcheck disable=SC2034
BUILD_DIR="$ROOT_DIR/build"
OUTPUT_DIR="$ROOT_DIR/output"
SOURCE_DIR=${MINIJINJA_SOURCE_DIR:-"$BUILD_DIR/source"}
SLICES_DIR="$BUILD_DIR/slices"
PLATFORMS_DIR="$BUILD_DIR/platforms"
TARGET_DIR="$BUILD_DIR/cargo-target"
TARGETS_FILE="$ROOT_DIR/config/apple-targets.txt"
SYMBOLS_FILE="$ROOT_DIR/config/required-symbols.txt"

MINIJINJA_REPOSITORY=${MINIJINJA_REPOSITORY:-https://github.com/plx/minijinja.git}
MINIJINJA_REF=${MINIJINJA_REF:-2.24.0}
MINIJINJA_EXPECTED_COMMIT=${MINIJINJA_EXPECTED_COMMIT:-0ca749f7ba507514fa6b052c74130ae6ae472e03}
MINIJINJA_STABLE_TOOLCHAIN=${MINIJINJA_STABLE_TOOLCHAIN:-1.90.0}
MINIJINJA_NIGHTLY_TOOLCHAIN=${MINIJINJA_NIGHTLY_TOOLCHAIN:-nightly-2025-11-04}
MINIJINJA_FEATURES=${MINIJINJA_FEATURES:-minijinja/unicode,minijinja/json,minijinja/urlencode,minijinja/speedups,minijinja/loop_controls}

LIBRARY_NAME=libMiniJinjaC.a
XCFRAMEWORK_NAME=MiniJinjaC.xcframework
ARCHIVE_NAME="$XCFRAMEWORK_NAME.zip"

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || die "required tool not found: $1"
}

require_file() {
  [ -f "$1" ] || die "required file not found: $1"
}

require_directory() {
  [ -d "$1" ] || die "required directory not found: $1"
}

assert_generated_path() {
  case "$1" in
    "$ROOT_DIR/build" | "$ROOT_DIR/output" | "$ROOT_DIR/build/"* | "$ROOT_DIR/output/"*) ;;
    *) die "refusing destructive operation outside repository build/output directories: $1" ;;
  esac
}

source_commit() {
  git -C "$SOURCE_DIR" rev-parse HEAD
}

source_epoch() {
  git -C "$SOURCE_DIR" show -s --format=%ct HEAD
}

build_fingerprint() {
  {
    printf 'source=%s\n' "$(source_commit)"
    printf 'stable=%s\n' "$(rustc "+$MINIJINJA_STABLE_TOOLCHAIN" --version)"
    printf 'nightly=%s\n' "$(rustc "+$MINIJINJA_NIGHTLY_TOOLCHAIN" --version)"
    printf 'features=%s\n' "$MINIJINJA_FEATURES"
    printf '%s\n' 'profile=release;opt=3;lto=thin;codegen-units=1;panic=unwind;strip=debuginfo'
    shasum -a 256 "$TARGETS_FILE" "$ROOT_DIR/scripts/build-slices.sh"
  } | shasum -a 256 | awk '{print $1}'
}

toolchain_for_mode() {
  case "$1" in
    stable) printf '%s\n' "$MINIJINJA_STABLE_TOOLCHAIN" ;;
    nightly) printf '%s\n' "$MINIJINJA_NIGHTLY_TOOLCHAIN" ;;
    *) die "unknown toolchain mode: $1" ;;
  esac
}

target_matches_selector() {
  target_id=$1
  target_group=$2
  selector=$3
  [ "$selector" = all ] || [ "$selector" = "$target_id" ] || [ "$selector" = "$target_group" ]
}
