#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool jq
require_tool lipo
require_tool nm
require_tool otool
require_tool plutil
require_tool swift
require_tool xcrun
require_file "$TARGETS_FILE"
require_file "$SYMBOLS_FILE"
require_file "$OUTPUT_DIR/$XCFRAMEWORK_NAME/Info.plist"
require_file "$OUTPUT_DIR/$XCFRAMEWORK_NAME/Licenses/MiniJinja-Apache-2.0.txt"
require_file "$OUTPUT_DIR/$XCFRAMEWORK_NAME/Licenses/THIRD-PARTY-NOTICES.txt"

cmp -s \
  "$SOURCE_DIR/LICENSE" \
  "$OUTPUT_DIR/$XCFRAMEWORK_NAME/Licenses/MiniJinja-Apache-2.0.txt" ||
  die "embedded MiniJinja license differs from the pinned source"
grep -q '^unicode-ident 1\.0\.18$' "$OUTPUT_DIR/$XCFRAMEWORK_NAME/Licenses/THIRD-PARTY-NOTICES.txt" ||
  die "third-party notices do not describe the locked runtime dependencies"

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/minijinja-xcframework-verify.XXXXXX")
cleanup() {
  case "$temporary_dir" in
    "${TMPDIR:-/tmp}"/*) rm -rf -- "$temporary_dir" ;;
  esac
}
trap cleanup EXIT

while IFS='|' read -r target_id target_group _rust_target clang_target sdk archive_arch _deployment_env deployment_min _toolchain_mode; do
  case "$target_id" in
    '' | \#*) continue ;;
  esac

  slice_library="$SLICES_DIR/$target_id/lib/$LIBRARY_NAME"
  group_include="$PLATFORMS_DIR/$target_group/include"
  require_file "$slice_library"
  require_file "$group_include/module.modulemap"

  actual_architectures=$(lipo -archs "$slice_library")
  case " $actual_architectures " in
    *" $archive_arch "*) ;;
    *) die "$target_id archive has [$actual_architectures], expected $archive_arch" ;;
  esac

  effective_minimum=$(otool -l "$slice_library" 2>/dev/null | awk '
    /cmd LC_BUILD_VERSION/ { capture = 1; next }
    capture && /minos/ { print $2; capture = 0 }
  ' | sort -V | tail -1)
  [ "$effective_minimum" = "$deployment_min" ] || die "$target_id has effective minimum $effective_minimum; expected $deployment_min"

  nm -gjU "$slice_library" 2>/dev/null | sed 's/^_//' | LC_ALL=C sort -u >"$temporary_dir/$target_id-symbols.txt"
  while IFS= read -r required_symbol; do
    [ -n "$required_symbol" ] || continue
    grep -Fxq "$required_symbol" "$temporary_dir/$target_id-symbols.txt" || die "$target_id is missing $required_symbol"
  done <"$SYMBOLS_FILE"

  sdkroot=$(xcrun --sdk "$sdk" --show-sdk-path)
  log "Checking Clang import for $target_id"
  xcrun --sdk "$sdk" clang \
    -target "$clang_target" \
    -isysroot "$sdkroot" \
    -fmodules \
    -fmodules-cache-path="$temporary_dir/clang-modules-$target_id" \
    -I "$group_include" \
    -fsyntax-only \
    "$ROOT_DIR/Tests/ImportSmoke.m"

  log "Checking Swift import for $target_id"
  xcrun --sdk "$sdk" swiftc \
    -target "$clang_target" \
    -sdk "$sdkroot" \
    -I "$group_include" \
    -module-cache-path "$temporary_dir/swift-modules-$target_id" \
    -typecheck \
    "$ROOT_DIR/Tests/ImportSmoke.swift"
done <"$TARGETS_FILE"

log "Validating XCFramework metadata"
plutil -lint "$OUTPUT_DIR/$XCFRAMEWORK_NAME/Info.plist"
plutil -convert json -o "$temporary_dir/Info.json" "$OUTPUT_DIR/$XCFRAMEWORK_NAME/Info.plist"
available_library_count=$(jq '.AvailableLibraries | length' "$temporary_dir/Info.json")
[ "$available_library_count" -eq 10 ] || die "XCFramework contains $available_library_count libraries; expected 10"
jq -e '
  def hasSlice($platform; $variant; $architectures):
    any(.AvailableLibraries[];
      .SupportedPlatform == $platform and
      (.SupportedPlatformVariant // "") == $variant and
      (.SupportedArchitectures | sort) == ($architectures | sort));
  hasSlice("macos"; ""; ["arm64", "x86_64"]) and
  hasSlice("ios"; ""; ["arm64"]) and
  hasSlice("ios"; "simulator"; ["arm64", "x86_64"]) and
  hasSlice("ios"; "maccatalyst"; ["arm64", "x86_64"]) and
  hasSlice("tvos"; ""; ["arm64"]) and
  hasSlice("tvos"; "simulator"; ["arm64", "x86_64"]) and
  hasSlice("watchos"; ""; ["arm64", "arm64_32", "armv7k"]) and
  hasSlice("watchos"; "simulator"; ["arm64", "x86_64"]) and
  hasSlice("xros"; ""; ["arm64"]) and
  hasSlice("xros"; "simulator"; ["arm64"])
' "$temporary_dir/Info.json" >/dev/null || die "XCFramework platform/variant/architecture matrix is incorrect"

while IFS= read -r bundled_header; do
  cmp -s "$SOURCE_DIR/minijinja-cabi/include/minijinja.h" "$bundled_header" || die "bundled header differs from pinned upstream header: $bundled_header"
done < <(find "$OUTPUT_DIR/$XCFRAMEWORK_NAME" -path '*/Headers/minijinja.h' -print)
if find "$OUTPUT_DIR/$XCFRAMEWORK_NAME" -name '*.apinotes' -print | grep -q .; then
  die "XCFramework unexpectedly contains API notes"
fi

host_arch=$(uname -m)
host_target="$host_arch-apple-macos12.0"
host_executable="$temporary_dir/host-smoke"
log "Linking and running host Swift smoke test"
xcrun --sdk macosx swiftc \
  -target "$host_target" \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -I "$PLATFORMS_DIR/macos/include" \
  -L "$PLATFORMS_DIR/macos/lib" \
  -lMiniJinjaC \
  "$ROOT_DIR/Tests/HostSmoke.swift" \
  -o "$host_executable"
"$host_executable"

log "Testing the local SwiftPM binary target"
swift test --package-path "$ROOT_DIR/MiniJinjaEvaluation"

log "All architecture, ABI, import, link, and package checks passed"
