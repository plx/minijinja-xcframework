#!/usr/bin/env bash

# Script to update Package.swift with new XCFramework release info
# Usage: ./update-package-swift.sh VERSION CHECKSUM

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 VERSION CHECKSUM"
    echo "Example: $0 2.5.0 abc123def456..."
    exit 1
fi

VERSION=$1
CHECKSUM=$2
REPO_URL="https://github.com/YOUR_ORG/minijinja-xcframework"  # Update this!

# Path to your Swift package
PACKAGE_PATH="../minijinja-swift/Package.swift"

# Create the new binaryTarget declaration
BINARY_TARGET="        .binaryTarget(
            name: \"minijinja\",
            url: \"${REPO_URL}/releases/download/v${VERSION}/minijinja.xcframework.zip\",
            checksum: \"${CHECKSUM}\"
        ),"

echo "📝 Updating Package.swift with:"
echo "   Version: $VERSION"
echo "   Checksum: $CHECKSUM"

# Update Package.swift (you may need to adjust this based on your exact format)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|\.binaryTarget.*minijinja.*checksum.*|${BINARY_TARGET}|" "$PACKAGE_PATH"
else
    # Linux
    sed -i "s|\.binaryTarget.*minijinja.*checksum.*|${BINARY_TARGET}|" "$PACKAGE_PATH"
fi

echo "✅ Package.swift updated successfully!"
echo ""
echo "Don't forget to:"
echo "1. Test the integration"
echo "2. Commit and push the changes"
echo "3. Tag the release in your Swift package if needed"
