#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

version=${1:?usage: release-notes.sh SOURCE_VERSION RELEASE_TAG [GITHUB_REPOSITORY]}
release_tag=${2:?usage: release-notes.sh SOURCE_VERSION RELEASE_TAG [GITHUB_REPOSITORY]}
release_repository=${3:-plx/minijinja-xcframework}

require_tool jq
require_file "$OUTPUT_DIR/MiniJinjaC.build-info.json"
require_file "$OUTPUT_DIR/$ARCHIVE_NAME.swiftpm-checksum"

source_repository=$(jq -r '.source.repository | sub("\\.git$"; "")' "$OUTPUT_DIR/MiniJinjaC.build-info.json")
source_commit=$(jq -r '.source.commit' "$OUTPUT_DIR/MiniJinjaC.build-info.json")
checksum=$(sed -n '1p' "$OUTPUT_DIR/$ARCHIVE_NAME.swiftpm-checksum")

printf 'Static MiniJinja C ABI libraries for Apple platforms, built from [MiniJinja %s](%s/commit/%s).\n\n' "$version" "$source_repository" "$source_commit"
printf '### Swift Package Manager\n\n'
printf '%s\n' '```swift'
printf '.binaryTarget(\n'
printf '  name: "MiniJinjaC",\n'
printf '  url: "https://github.com/%s/releases/download/%s/%s",\n' "$release_repository" "$release_tag" "$ARCHIVE_NAME"
printf '  checksum: "%s"\n' "$checksum"
printf ')\n'
printf '%s\n\n' '```'
# shellcheck disable=SC2016 # Markdown code spans are intentionally literal.
printf 'Import the implementation module with `import MiniJinjaC`.\n\n'
printf '### Platforms\n\n'
printf '%s\n' \
  '- macOS 12+: arm64 and x86_64' \
  '- iOS 15+: arm64 device; arm64 and x86_64 simulator' \
  '- Mac Catalyst 15+: arm64 and x86_64' \
  '- tvOS 15+: arm64 device; arm64 and x86_64 simulator' \
  '- watchOS 8+: arm64_32 and armv7k device; arm64 and x86_64 simulator; arm64 device on watchOS 26+' \
  '- visionOS 1+: arm64 device and simulator'
printf '\nThe archive is accompanied by SHA-256 and SwiftPM checksums, the exact Cargo.lock, build metadata, an SPDX SBOM, and GitHub build/SBOM attestations.\n'
