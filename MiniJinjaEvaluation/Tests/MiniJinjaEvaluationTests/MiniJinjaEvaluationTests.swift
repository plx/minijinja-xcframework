import Testing
@testable import MiniJinjaEvaluation
import MiniJinjaC

@Test
func doesCanWeUseMJValueExist() {
  #expect(canWeUseMJValue == nil)
}

private func withTemporaryMJValue<R>(
  _ factory: @autoclosure () throws -> mj_value,
  _ body: (mj_value) throws -> R
) rethrows -> R {
  var value = try factory()
  defer {
    mj_value_decref(&value)
  }
  return try body(value)
}

@Test
func canWeCreateMJBools() {
  withTemporaryMJValue(mj_value_new_bool(true)) {
    #expect(mj_value_is_true($0))
  }
  withTemporaryMJValue(mj_value_new_bool(false)) {
    #expect(!mj_value_is_true($0))
  }
}

@Test
func canWeCallMJFunctions() {
  withTemporaryMJValue(mj_value_new_none()) {
    #expect(mj_value_get_kind($0) == .noValue)
  }
  withTemporaryMJValue(mj_value_new_undefined()) {
    #expect(mj_value_get_kind($0) == .undefined)
  }
  withTemporaryMJValue(mj_value_new_list()) {
    #expect(mj_value_get_kind($0) == .sequence)
  }
}
