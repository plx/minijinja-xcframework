import MiniJinjaC

/// A Swift evaluation package for the MiniJinja C API.
///
/// This package exists solely for local development, experimentation, and verification
/// of the minijinja.xcframework packaging. It provides a convenient way to:
///
/// - Test that the XCFramework is properly structured and linkable
/// - Verify that the module map and APINotes are working correctly
/// - Experiment with Swift projections of the C API
/// - Validate changes to the build process and packaging
///
/// This package references the XCFramework directly from the `output/` directory,
/// so rebuilding with `just build` immediately makes changes available here.
public struct MiniJinjaEvaluation {
    public init() {}

    /// Verify that the MiniJinja C module can be imported and basic types are accessible.
    ///
    /// This is a minimal smoke test to ensure the C API is properly exposed.
    /// Returns `true` if the module appears to be working correctly.
    public func verifyModuleAccess() -> Bool {
        // Create an uninitialized mj_value to verify the type is accessible
        // This doesn't actually use the C API yet, just verifies we can access the types
        var _: mj_value

        // If we got here without compilation errors, the module is accessible
        return true
    }

    /// Returns a description of this evaluation package.
    public var description: String {
        """
        MiniJinjaEvaluation Package

        This package provides local evaluation and testing capabilities for the
        minijinja.xcframework. It references the XCFramework from ../output/ and
        can be used to quickly verify changes to:

        - XCFramework structure and packaging
        - Module maps and Clang modules
        - APINotes customizations
        - Swift API projections

        To use: rebuild the XCFramework with `just build`, then run tests here
        with `swift test` to verify everything works.
        """
    }
}
