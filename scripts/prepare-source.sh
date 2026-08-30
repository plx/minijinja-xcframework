#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool git

if [ -n "${MINIJINJA_SOURCE_DIR:-}" ]; then
  git -C "$SOURCE_DIR" rev-parse --git-dir >/dev/null 2>&1 || die "not a Git checkout: $SOURCE_DIR"
  log "Using existing MiniJinja checkout at $SOURCE_DIR"
  resolved_repository=$(git -C "$SOURCE_DIR" remote get-url origin 2>/dev/null || printf 'local:%s\n' "$SOURCE_DIR")
  resolved_ref=$(git -C "$SOURCE_DIR" describe --tags --exact-match HEAD 2>/dev/null || git -C "$SOURCE_DIR" rev-parse --abbrev-ref HEAD)
else
  assert_generated_path "$SOURCE_DIR"
  rm -rf -- "$SOURCE_DIR"
  mkdir -p "$SOURCE_DIR"

  log "Fetching $MINIJINJA_REPOSITORY at $MINIJINJA_REF"
  git -C "$SOURCE_DIR" init --quiet
  git -C "$SOURCE_DIR" remote add origin "$MINIJINJA_REPOSITORY"
  git -C "$SOURCE_DIR" fetch --quiet --depth=1 origin "$MINIJINJA_REF"
  git -C "$SOURCE_DIR" -c advice.detachedHead=false checkout --quiet --detach FETCH_HEAD
  git -C "$SOURCE_DIR" submodule update --init --recursive --depth=1
  resolved_repository=$MINIJINJA_REPOSITORY
  resolved_ref=$MINIJINJA_REF
fi

require_file "$SOURCE_DIR/Cargo.lock"
require_file "$SOURCE_DIR/minijinja-cabi/Cargo.toml"
require_file "$SOURCE_DIR/minijinja-cabi/include/minijinja.h"

resolved_commit=$(source_commit)
if [ -n "$MINIJINJA_EXPECTED_COMMIT" ] && [ "$resolved_commit" != "$MINIJINJA_EXPECTED_COMMIT" ]; then
  die "source resolved to $resolved_commit; expected $MINIJINJA_EXPECTED_COMMIT"
fi
if [ -n "$(git -C "$SOURCE_DIR" status --porcelain --untracked-files=all)" ]; then
  die "source checkout is dirty; commit or remove local changes before building"
fi

mkdir -p "$BUILD_DIR/provenance"
printf '%s\n' "$resolved_repository" >"$BUILD_DIR/provenance/source-repository"
printf '%s\n' "$resolved_ref" >"$BUILD_DIR/provenance/source-ref"
printf '%s\n' "$resolved_commit" >"$BUILD_DIR/provenance/source-commit"
source_epoch >"$BUILD_DIR/provenance/source-date-epoch"

log "Prepared MiniJinja source at $resolved_commit"
