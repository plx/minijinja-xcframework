#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

printf 'MiniJinja repository: %s\n' "$MINIJINJA_REPOSITORY"
printf 'MiniJinja ref:        %s\n' "$MINIJINJA_REF"
printf 'Expected commit:      %s\n' "$MINIJINJA_EXPECTED_COMMIT"
printf 'Stable Rust:          %s\n' "$MINIJINJA_STABLE_TOOLCHAIN"
printf 'Nightly Rust:         %s\n' "$MINIJINJA_NIGHTLY_TOOLCHAIN"
printf 'Features:             %s\n' "$MINIJINJA_FEATURES"
printf 'Build directory:      %s\n' "$BUILD_DIR"
printf 'Output directory:     %s\n' "$OUTPUT_DIR"
printf '\nConfigured targets:\n'
awk -F '|' '!/^#/ && NF { printf "  %-28s %-32s %s+\n", $1, $3, $8 }' "$TARGETS_FILE"
