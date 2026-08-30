#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool cargo
require_tool jq
require_tool rustc
require_file "$SOURCE_DIR/LICENSE"
require_directory "$OUTPUT_DIR/$XCFRAMEWORK_NAME"

licenses_dir="$OUTPUT_DIR/$XCFRAMEWORK_NAME/Licenses"
assert_generated_path "$licenses_dir"
rm -rf -- "$licenses_dir"
mkdir -p "$licenses_dir"

cp "$SOURCE_DIR/LICENSE" "$licenses_dir/MiniJinja-Apache-2.0.txt"

metadata_file=$(mktemp "${TMPDIR:-/tmp}/minijinja-metadata.XXXXXX")
packages_file=$(mktemp "${TMPDIR:-/tmp}/minijinja-packages.XXXXXX")
trap 'rm -f -- "$metadata_file" "$packages_file"' EXIT

cargo "+$MINIJINJA_STABLE_TOOLCHAIN" metadata \
  --locked \
  --filter-platform aarch64-apple-darwin \
  --format-version 1 \
  --features "$MINIJINJA_FEATURES" \
  --manifest-path "$SOURCE_DIR/Cargo.toml" \
  >"$metadata_file"

cargo "+$MINIJINJA_STABLE_TOOLCHAIN" tree \
  --locked \
  --edges normal,build \
  --features "$MINIJINJA_FEATURES" \
  --manifest-path "$SOURCE_DIR/Cargo.toml" \
  --package minijinja-cabi \
  --prefix none \
  --target aarch64-apple-darwin \
  --format '{p}' |
  sed -E 's/ \(.*\)$//' |
  awk '{ version = $2; sub(/^v/, "", version); print $1 "\t" version }' |
  LC_ALL=C sort -u \
    >"$packages_file"

notices_file="$licenses_dir/THIRD-PARTY-NOTICES.txt"
{
  printf '%s\n\n' 'Third-Party Notices for MiniJinjaC'
  printf '%s\n' 'This file contains the notices shipped by every non-MiniJinja Cargo dependency linked into MiniJinjaC.'
  printf '%s\n\n' 'The dependency set is derived from the locked, feature-enabled release graph; build-only and development-only packages are excluded.'
} >"$notices_file"

while IFS="$(printf '\t')" read -r package_name package_version; do
  case "$package_name" in
    minijinja | minijinja-cabi) continue ;;
  esac

  package_json=$(jq -ce \
    --arg name "$package_name" \
    --arg version "$package_version" \
    'first(.packages[] | select(.name == $name and .version == $version))' \
    "$metadata_file") || die "metadata missing for $package_name $package_version"
  license_expression=$(printf '%s' "$package_json" | jq -r '.license // "UNKNOWN"')
  package_source=$(printf '%s' "$package_json" | jq -r '.repository // .homepage // "not declared"')
  manifest_path=$(printf '%s' "$package_json" | jq -r '.manifest_path')
  manifest_dir=${manifest_path%/Cargo.toml}

  license_files=$(find "$manifest_dir" -maxdepth 1 -type f \( \
    -iname 'COPYING*' -o \
    -iname 'COPYRIGHT*' -o \
    -iname 'LICENSE*' -o \
    -iname 'NOTICE*' \
    \) -print | LC_ALL=C sort)
  [ -n "$license_files" ] || die "no packaged license notice found for $package_name $package_version"

  {
    printf '%s\n' '=============================================================================='
    printf '%s %s\n' "$package_name" "$package_version"
    printf 'SPDX license expression: %s\n' "$license_expression"
    printf 'Source: %s\n\n' "$package_source"
    while IFS= read -r license_file; do
      printf '%s\n' "--- ${license_file##*/} ---"
      cat "$license_file"
      printf '\n\n'
    done <<EOF
$license_files
EOF
  } >>"$notices_file"
done <"$packages_file"

for toolchain in "$MINIJINJA_STABLE_TOOLCHAIN" "$MINIJINJA_NIGHTLY_TOOLCHAIN"; do
  rust_doc_dir=$(rustc "+$toolchain" --print sysroot)/share/doc/rust
  require_file "$rust_doc_dir/COPYRIGHT-library.html"
  require_directory "$rust_doc_dir/licenses"

  toolchain_licenses_dir="$licenses_dir/Rust-$toolchain"
  mkdir -p "$toolchain_licenses_dir"
  cp "$rust_doc_dir/COPYRIGHT-library.html" "$toolchain_licenses_dir/"
  cp -R "$rust_doc_dir/licenses" "$toolchain_licenses_dir/"
done

log "Embedded MiniJinja, Cargo dependency, and Rust runtime notices"
