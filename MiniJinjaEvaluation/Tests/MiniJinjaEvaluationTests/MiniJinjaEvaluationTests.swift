import XCTest
@testable import MiniJinjaEvaluation
import MiniJinjaC

/// Unit tests for evaluating the MiniJinja C API integration.
///
/// These tests serve several purposes:
/// - Verify that the XCFramework is properly structured and linkable
/// - Validate that the Clang module (MiniJinjaC) can be imported
/// - Test that APINotes customizations are working as expected
/// - Ensure the C API types and functions are accessible from Swift
final class MiniJinjaEvaluationTests: XCTestCase {

    /// Test that we can create an instance of the evaluation package.
    func testPackageInitialization() throws {
        let evaluation = MiniJinjaEvaluation()
        XCTAssertNotNil(evaluation)
    }

    /// Test that the MiniJinja C module is accessible and types can be used.
    func testModuleAccess() throws {
        let evaluation = MiniJinjaEvaluation()
        let result = evaluation.verifyModuleAccess()
        XCTAssertTrue(result, "Should be able to access MiniJinjaC module types")
    }

    /// Test that we can access the package description.
    func testDescription() throws {
        let evaluation = MiniJinjaEvaluation()
        let description = evaluation.description
        XCTAssertFalse(description.isEmpty)
        XCTAssertTrue(description.contains("MiniJinjaEvaluation"))
    }

    /// Test direct access to MiniJinja C API types.
    ///
    /// This test directly imports MiniJinjaC to verify that the C types
    /// are properly exposed and accessible. This is where you'd add tests
    /// for APINotes customizations (nullability, naming, etc.).
    func testDirectCAPIAccess() throws {
        // Verify we can reference C API types directly
        // This is a compile-time check more than a runtime check
        var _: mj_value

        // If we got here, the C API types are accessible
        XCTAssert(true, "C API types are accessible")
    }

    /// Placeholder test for future API evaluation.
    ///
    /// As you develop the Swift wrapper and experiment with APINotes,
    /// add more specific tests here to validate:
    /// - Function calls work correctly
    /// - Memory management behaves as expected
    /// - APINotes annotations are applied properly
    /// - Error handling works
    func testFutureAPIEvaluation() throws {
        // TODO: Add real API tests once you start calling C functions
        XCTAssert(true, "Placeholder for future API tests")
    }
}
