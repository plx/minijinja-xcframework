@import MiniJinjaC;

_Static_assert(sizeof(mj_value) == 24, "mj_value ABI size changed");
_Static_assert(_Alignof(mj_value) == 8, "mj_value ABI alignment changed");

static void exercise_import(void) {
  mj_env *environment = mj_env_new();
  mj_env_set_debug(environment, true);
  mj_env_free(environment);
}
