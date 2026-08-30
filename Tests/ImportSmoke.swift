import MiniJinjaC

func exerciseRawCImporter(_ environment: OpaquePointer?) {
  mj_env_set_debug(environment, true)
  mj_env_set_undefined_behavior(environment, MJ_UNDEFINED_BEHAVIOR_STRICT)

  let _: mj_auto_escape = MJ_AUTO_ESCAPE_HTML
  let _: mj_err_kind = MJ_ERR_KIND_SYNTAX_ERROR
  let _: mj_undefined_behavior = MJ_UNDEFINED_BEHAVIOR_CHAINABLE
  let _: mj_value_kind = MJ_VALUE_KIND_NONE
}
