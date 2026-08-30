#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool jq
require_tool shasum
require_tool swift
require_tool zip
require_directory "$OUTPUT_DIR/$XCFRAMEWORK_NAME"

"$ROOT_DIR/scripts/write-build-metadata.sh"

package_dir="$BUILD_DIR/package"
assert_generated_path "$package_dir"
rm -rf -- "$package_dir"
mkdir -p "$package_dir"
cp -R "$OUTPUT_DIR/$XCFRAMEWORK_NAME" "$package_dir/$XCFRAMEWORK_NAME"
xattr -cr "$package_dir/$XCFRAMEWORK_NAME" 2>/dev/null || true

source_date_epoch=$(source_epoch)
archive_timestamp=$(date -u -r "$source_date_epoch" +%Y%m%d%H%M.%S)
find "$package_dir/$XCFRAMEWORK_NAME" -exec touch -h -t "$archive_timestamp" {} +

archive_path="$OUTPUT_DIR/$ARCHIVE_NAME"
rm -f -- "$archive_path"
(
  cd "$package_dir"
  find "$XCFRAMEWORK_NAME" -print | LC_ALL=C sort | COPYFILE_DISABLE=1 zip -X -q "$archive_path" -@
)

sha256=$(shasum -a 256 "$archive_path" | awk '{print $1}')
swiftpm_checksum=$(swift package compute-checksum "$archive_path")
archive_size=$(stat -f %z "$archive_path")

printf '%s  %s\n' "$sha256" "$ARCHIVE_NAME" >"$OUTPUT_DIR/$ARCHIVE_NAME.sha256"
printf '%s\n' "$swiftpm_checksum" >"$OUTPUT_DIR/$ARCHIVE_NAME.swiftpm-checksum"
jq -n \
  --arg artifact "$ARCHIVE_NAME" \
  --arg sha256 "$sha256" \
  --arg swiftPackageChecksum "$swiftpm_checksum" \
  --argjson size "$archive_size" \
  '{artifact: $artifact, sha256: $sha256, swiftPackageChecksum: $swiftPackageChecksum, size: $size}' \
  >"$OUTPUT_DIR/MiniJinjaC.checksums.json"

log "Packaged $archive_path"
log "SHA-256 / SwiftPM checksum: $sha256"
