#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

selector=${1:-all}

require_tool cargo
require_tool shasum
require_tool xcrun
require_file "$TARGETS_FILE"
require_file "$SOURCE_DIR/minijinja-cabi/include/minijinja.h"

source_date_epoch=$(source_epoch)
current_build_fingerprint=$(build_fingerprint)
mkdir -p "$SLICES_DIR" "$TARGET_DIR"
built_count=0

while IFS='|' read -r target_id target_group rust_target clang_target sdk archive_arch deployment_env deployment_min toolchain_mode; do
  case "$target_id" in
    '' | \#*) continue ;;
  esac
  if ! target_matches_selector "$target_id" "$target_group" "$selector"; then
    continue
  fi

  toolchain=$(toolchain_for_mode "$toolchain_mode")
  sdkroot=$(xcrun --sdk "$sdk" --show-sdk-path)
  clang=$(xcrun --sdk "$sdk" --find clang)
  cc_env=CC_$(printf '%s' "$rust_target" | tr '[:lower:]-' '[:upper:]_')
  cargo_target_dir="$TARGET_DIR/$toolchain_mode"
  slice_dir="$SLICES_DIR/$target_id"

  log "Building $target_id ($rust_target, Rust $toolchain)"
  mkdir -p "$slice_dir/lib"

  # Keep the array non-empty for macOS's Bash 3.2 under `set -u`.
  cargo_args=(--color=always)
  if [ "$toolchain_mode" = nightly ]; then
    # shellcheck disable=SC2054 # This is one Cargo argument containing a comma.
    cargo_args+=(-Zbuild-std=std,panic_unwind)
  fi

  env \
    "$deployment_env=$deployment_min" \
    "$cc_env=$clang" \
    SDKROOT="$sdkroot" \
    SOURCE_DATE_EPOCH="$source_date_epoch" \
    ZERO_AR_DATE=1 \
    CARGO_PROFILE_RELEASE_OPT_LEVEL=3 \
    CARGO_PROFILE_RELEASE_LTO=thin \
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
    CARGO_PROFILE_RELEASE_PANIC=unwind \
    CARGO_PROFILE_RELEASE_STRIP=debuginfo \
    RUSTFLAGS="--remap-path-prefix=$SOURCE_DIR=/usr/src/minijinja -C debuginfo=0" \
    cargo "+$toolchain" rustc \
    --manifest-path "$SOURCE_DIR/Cargo.toml" \
    --locked \
    --package minijinja-cabi \
    --lib \
    --release \
    --target "$rust_target" \
    --target-dir "$cargo_target_dir" \
    --features "$MINIJINJA_FEATURES" \
    --crate-type staticlib \
    --config "target.$rust_target.linker=\"$clang\"" \
    "${cargo_args[@]}"

  built_library="$cargo_target_dir/$rust_target/release/libminijinja_cabi.a"
  require_file "$built_library"
  cp "$built_library" "$slice_dir/lib/$LIBRARY_NAME"

  printf '%s\n' "$rust_target" >"$slice_dir/rust-target"
  printf '%s\n' "$clang_target" >"$slice_dir/clang-target"
  printf '%s\n' "$sdk" >"$slice_dir/sdk"
  printf '%s\n' "$archive_arch" >"$slice_dir/architecture"
  printf '%s\n' "$current_build_fingerprint" >"$slice_dir/build-fingerprint"
  built_count=$((built_count + 1))
done <"$TARGETS_FILE"

[ "$built_count" -gt 0 ] || die "selector matched no targets: $selector"
log "Built $built_count architecture slice(s)"
