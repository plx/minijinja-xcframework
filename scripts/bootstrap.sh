#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool rustup

log "Installing Rust $MINIJINJA_STABLE_TOOLCHAIN"
rustup toolchain install "$MINIJINJA_STABLE_TOOLCHAIN" --profile minimal --component rust-docs

log "Installing Rust $MINIJINJA_NIGHTLY_TOOLCHAIN with rust-src and license documentation"
rustup toolchain install "$MINIJINJA_NIGHTLY_TOOLCHAIN" --profile minimal --component rust-src --component rust-docs

stable_targets='aarch64-apple-darwin aarch64-apple-ios aarch64-apple-ios-macabi aarch64-apple-ios-sim x86_64-apple-darwin x86_64-apple-ios x86_64-apple-ios-macabi'
for target in $stable_targets; do
  log "Installing stable Rust target $target"
  rustup target add "$target" --toolchain "$MINIJINJA_STABLE_TOOLCHAIN"
done

log "Toolchains are ready"
