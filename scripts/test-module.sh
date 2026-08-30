#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

require_tool xcrun

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/minijinja-module-test.XXXXXX")
cleanup() {
  case "$temporary_dir" in
    "${TMPDIR:-/tmp}"/*) rm -rf -- "$temporary_dir" ;;
  esac
}
trap cleanup EXIT

cp "$ROOT_DIR/module.modulemap" "$temporary_dir/"

cat >"$temporary_dir/minijinja.h" <<'HEADER'
#include <stdbool.h>
#include <stdint.h>

typedef enum mj_auto_escape {
  MJ_AUTO_ESCAPE_NONE,
  MJ_AUTO_ESCAPE_HTML,
} mj_auto_escape;

typedef enum mj_err_kind {
  MJ_ERR_KIND_NON_PRIMITIVE,
  MJ_ERR_KIND_NON_KEY,
  MJ_ERR_KIND_INVALID_OPERATION,
  MJ_ERR_KIND_SYNTAX_ERROR,
  MJ_ERR_KIND_TEMPLATE_NOT_FOUND,
  MJ_ERR_KIND_TOO_MANY_ARGUMENTS,
  MJ_ERR_KIND_MISSING_ARGUMENT,
  MJ_ERR_KIND_UNKNOWN_FILTER,
  MJ_ERR_KIND_UNKNOWN_FUNCTION,
  MJ_ERR_KIND_UNKNOWN_TEST,
  MJ_ERR_KIND_UNKNOWN_METHOD,
  MJ_ERR_KIND_BAD_ESCAPE,
  MJ_ERR_KIND_UNDEFINED_ERROR,
  MJ_ERROR_KIND_BAD_SERIALIZTION,
  MJ_ERR_KIND_BAD_INCLUDE,
  MJ_ERR_KIND_EVAL_BLOCK,
  MJ_ERR_KIND_CANNOT_UNPACK,
  MJ_ERR_KIND_WRITE_FAILURE,
  MJ_ERR_KIND_UNKNOWN,
} mj_err_kind;

typedef enum mj_undefined_behavior {
  MJ_UNDEFINED_BEHAVIOR_LENIENT,
  MJ_UNDEFINED_BEHAVIOR_STRICT,
  MJ_UNDEFINED_BEHAVIOR_CHAINABLE,
} mj_undefined_behavior;

typedef enum mj_value_kind {
  MJ_VALUE_KIND_UNDEFINED,
  MJ_VALUE_KIND_NONE,
  MJ_VALUE_KIND_BOOL,
  MJ_VALUE_KIND_NUMBER,
  MJ_VALUE_KIND_STRING,
  MJ_VALUE_KIND_BYTES,
  MJ_VALUE_KIND_SEQ,
  MJ_VALUE_KIND_MAP,
  MJ_VALUE_KIND_ITERABLE,
  MJ_VALUE_KIND_PLAIN,
  MJ_VALUE_KIND_INVALID,
} mj_value_kind;

typedef struct mj_env mj_env;
typedef struct mj_value { uint64_t _opaque[3]; } mj_value;

mj_env *mj_env_new(void);
void mj_env_free(mj_env *environment);
void mj_env_set_debug(mj_env *environment, bool enabled);
void mj_env_set_undefined_behavior(mj_env *environment, mj_undefined_behavior behavior);
HEADER

cat >"$temporary_dir/import.m" <<'OBJC'
@import MiniJinjaC;
_Static_assert(sizeof(mj_value) == 24, "mj_value ABI changed");
OBJC

cat >"$temporary_dir/import.swift" <<'SWIFT'
import MiniJinjaC
func check(_ environment: OpaquePointer?) {
  mj_env_set_debug(environment, true)
  mj_env_set_undefined_behavior(environment, MJ_UNDEFINED_BEHAVIOR_STRICT)
  let _: mj_auto_escape = MJ_AUTO_ESCAPE_HTML
  let _: mj_err_kind = MJ_ERROR_KIND_BAD_SERIALIZTION
  let _: mj_value_kind = MJ_VALUE_KIND_SEQ
}
SWIFT

sdkroot=$(xcrun --sdk macosx --show-sdk-path)
xcrun --sdk macosx clang \
  -fmodules \
  -fmodules-cache-path="$temporary_dir/clang-modules" \
  -I "$temporary_dir" \
  -fsyntax-only \
  "$temporary_dir/import.m"
xcrun --sdk macosx swiftc \
  -sdk "$sdkroot" \
  -I "$temporary_dir" \
  -module-cache-path "$temporary_dir/swift-modules" \
  -typecheck \
  "$temporary_dir/import.swift"

log "Raw C module map passed Clang and Swift import tests"
