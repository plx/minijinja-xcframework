#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool lipo
require_tool shasum
require_tool xcodebuild
require_file "$TARGETS_FILE"
require_file "$ROOT_DIR/module.modulemap"
require_file "$SOURCE_DIR/minijinja-cabi/include/minijinja.h"

assert_generated_path "$PLATFORMS_DIR"
assert_generated_path "$OUTPUT_DIR"
rm -rf -- "$PLATFORMS_DIR" "${OUTPUT_DIR:?}/$XCFRAMEWORK_NAME"
mkdir -p "$PLATFORMS_DIR" "$OUTPUT_DIR"
current_build_fingerprint=$(build_fingerprint)

groups='macos ios ios-simulator maccatalyst tvos tvos-simulator watchos watchos-simulator visionos visionos-simulator'

for group in $groups; do
  group_dir="$PLATFORMS_DIR/$group"
  mkdir -p "$group_dir/lib" "$group_dir/include"
  libraries=()

  while IFS='|' read -r target_id target_group _rust_target _clang_target _sdk _archive_arch _deployment_env _deployment_min _toolchain_mode; do
    case "$target_id" in
      '' | \#*) continue ;;
    esac
    [ "$target_group" = "$group" ] || continue
    library="$SLICES_DIR/$target_id/lib/$LIBRARY_NAME"
    require_file "$library"
    require_file "$SLICES_DIR/$target_id/build-fingerprint"
    slice_build_fingerprint=$(sed -n '1p' "$SLICES_DIR/$target_id/build-fingerprint")
    [ "$slice_build_fingerprint" = "$current_build_fingerprint" ] || die "$target_id was built from a different source or configuration; rebuild slices"
    libraries+=("$library")
  done <"$TARGETS_FILE"

  library_count=${#libraries[@]}
  [ "$library_count" -gt 0 ] || die "no libraries configured for $group"
  if [ "$library_count" -eq 1 ]; then
    cp "${libraries[0]}" "$group_dir/lib/$LIBRARY_NAME"
  else
    lipo -create "${libraries[@]}" -output "$group_dir/lib/$LIBRARY_NAME"
  fi

  cp "$SOURCE_DIR/minijinja-cabi/include/minijinja.h" "$group_dir/include/"
  cp "$ROOT_DIR/module.modulemap" "$group_dir/include/"
done

log "Creating $XCFRAMEWORK_NAME"
xcodebuild -create-xcframework \
  -library "$PLATFORMS_DIR/macos/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/macos/include" \
  -library "$PLATFORMS_DIR/ios/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/ios/include" \
  -library "$PLATFORMS_DIR/ios-simulator/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/ios-simulator/include" \
  -library "$PLATFORMS_DIR/maccatalyst/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/maccatalyst/include" \
  -library "$PLATFORMS_DIR/tvos/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/tvos/include" \
  -library "$PLATFORMS_DIR/tvos-simulator/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/tvos-simulator/include" \
  -library "$PLATFORMS_DIR/watchos/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/watchos/include" \
  -library "$PLATFORMS_DIR/watchos-simulator/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/watchos-simulator/include" \
  -library "$PLATFORMS_DIR/visionos/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/visionos/include" \
  -library "$PLATFORMS_DIR/visionos-simulator/lib/$LIBRARY_NAME" -headers "$PLATFORMS_DIR/visionos-simulator/include" \
  -output "$OUTPUT_DIR/$XCFRAMEWORK_NAME"

"$ROOT_DIR/scripts/write-licenses.sh"

log "Created $OUTPUT_DIR/$XCFRAMEWORK_NAME"
