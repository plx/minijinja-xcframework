#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool actionlint
require_tool awk
require_tool just
require_tool shellcheck
require_tool shfmt

log "Checking shell scripts"
shellcheck -x -e SC1091,SC2034 "$ROOT_DIR"/scripts/*.sh "$ROOT_DIR/test_module_verification.sh"
shfmt -d -i 2 -ci "$ROOT_DIR"/scripts/*.sh "$ROOT_DIR/test_module_verification.sh"

log "Checking justfile"
just --justfile "$ROOT_DIR/justfile" --fmt --check

log "Checking GitHub Actions workflows"
actionlint "$ROOT_DIR"/.github/workflows/*.yml

log "Checking platform and ABI manifests"
awk -F '|' '
  BEGIN { failed = 0 }
  /^#/ || NF == 0 { next }
  NF != 9 { print FILENAME ":" FNR ": expected 9 fields, found " NF > "/dev/stderr"; failed = 1 }
  seen[$1]++ { print FILENAME ":" FNR ": duplicate target id " $1 > "/dev/stderr"; failed = 1 }
  END { exit failed }
' "$TARGETS_FILE"

symbol_count=$(grep -c '^mj_' "$SYMBOLS_FILE")
unique_symbol_count=$(LC_ALL=C sort -u "$SYMBOLS_FILE" | grep -c '^mj_')
[ "$symbol_count" -eq 68 ] || die "required-symbols.txt contains $symbol_count symbols; expected 68"
[ "$symbol_count" -eq "$unique_symbol_count" ] || die "required-symbols.txt contains duplicates"

log "Static checks passed"
