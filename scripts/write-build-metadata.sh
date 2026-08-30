#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool cargo
require_tool jq
require_tool xcodebuild
require_file "$BUILD_DIR/provenance/source-repository"
require_file "$BUILD_DIR/provenance/source-ref"
require_file "$BUILD_DIR/provenance/source-commit"
require_file "$TARGETS_FILE"

mkdir -p "$OUTPUT_DIR" "$BUILD_DIR/metadata"
targets_ndjson="$BUILD_DIR/metadata/targets.ndjson"
: >"$targets_ndjson"

while IFS='|' read -r target_id target_group rust_target clang_target sdk archive_arch _deployment_env deployment_min toolchain_mode; do
  case "$target_id" in
    '' | \#*) continue ;;
  esac
  sdk_version=$(xcrun --sdk "$sdk" --show-sdk-version)
  jq -cn \
    --arg id "$target_id" \
    --arg group "$target_group" \
    --arg rustTarget "$rust_target" \
    --arg clangTarget "$clang_target" \
    --arg sdk "$sdk" \
    --arg sdkVersion "$sdk_version" \
    --arg architecture "$archive_arch" \
    --arg deploymentTarget "$deployment_min" \
    --arg toolchain "$toolchain_mode" \
    '{id: $id, group: $group, rustTarget: $rustTarget, clangTarget: $clangTarget, sdk: $sdk, sdkVersion: $sdkVersion, architecture: $architecture, deploymentTarget: $deploymentTarget, toolchain: $toolchain}' \
    >>"$targets_ndjson"
done <"$TARGETS_FILE"

targets_json=$(jq -cs '.' "$targets_ndjson")
source_repository=$(sed -n '1p' "$BUILD_DIR/provenance/source-repository")
source_ref=$(sed -n '1p' "$BUILD_DIR/provenance/source-ref")
resolved_commit=$(sed -n '1p' "$BUILD_DIR/provenance/source-commit")
source_date_epoch=$(sed -n '1p' "$BUILD_DIR/provenance/source-date-epoch")
source_version=$(cargo "+$MINIJINJA_STABLE_TOOLCHAIN" metadata --locked --no-deps --format-version 1 --manifest-path "$SOURCE_DIR/Cargo.toml" | jq -r '.packages[] | select(.name == "minijinja-cabi") | .version')
stable_rust=$(rustc "+$MINIJINJA_STABLE_TOOLCHAIN" --version)
nightly_rust=$(rustc "+$MINIJINJA_NIGHTLY_TOOLCHAIN" --version)
xcode_version=$(xcodebuild -version | tr '\n' ';' | sed 's/;$//')
swift_version=$(swift --version 2>&1 | tr '\n' ';' | sed 's/;$//')

jq -n \
  --arg schemaVersion "1" \
  --arg artifact "$XCFRAMEWORK_NAME" \
  --arg module "MiniJinjaC" \
  --arg library "$LIBRARY_NAME" \
  --arg sourceRepository "$source_repository" \
  --arg sourceRef "$source_ref" \
  --arg sourceCommit "$resolved_commit" \
  --arg sourceVersion "$source_version" \
  --argjson sourceDateEpoch "$source_date_epoch" \
  --arg stableRust "$stable_rust" \
  --arg nightlyRust "$nightly_rust" \
  --arg xcode "$xcode_version" \
  --arg swift "$swift_version" \
  --arg features "$MINIJINJA_FEATURES" \
  --argjson targets "$targets_json" \
  '{
    schemaVersion: ($schemaVersion | tonumber),
    artifact: {name: $artifact, module: $module, staticLibrary: $library},
    source: {repository: $sourceRepository, requestedRef: $sourceRef, commit: $sourceCommit, version: $sourceVersion, sourceDateEpoch: $sourceDateEpoch},
    toolchains: {stableRust: $stableRust, nightlyRust: $nightlyRust, Xcode: $xcode, Swift: $swift},
    build: {profile: "release", panic: "unwind", optimizationLevel: "3", lto: "thin", codegenUnits: 1, strip: "debuginfo", features: ($features | split(","))},
    targets: $targets
  }' >"$OUTPUT_DIR/MiniJinjaC.build-info.json"

cp "$SOURCE_DIR/Cargo.lock" "$OUTPUT_DIR/MiniJinjaC.Cargo.lock"
log "Wrote build metadata and pinned dependency lockfile"
