#!/bin/bash
# verify_patch_before_build.sh - Verify iOS patch is present before CI/CD build
# This script MUST pass before compilation starts

set -e

echo "🔍 ========================================"
echo "🔍 VERIFYING iOS PATCH BEFORE BUILD"
echo "🔍 ========================================"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Path to patched file
PATCH_FILE="Sources/Tor/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c"
PATCH_MARKER="iOS PATCH"

# Check if file exists
if [ ! -f "$PATCH_FILE" ]; then
    echo "❌ ERROR: File not found: $PATCH_FILE"
    echo "   This file must exist before building XCFramework"
    exit 1
fi

# Check for patch marker
if ! grep -q "$PATCH_MARKER" "$PATCH_FILE"; then
    echo "❌ ERROR: iOS patch not found in $PATCH_FILE"
    echo ""
    echo "   Expected marker: '$PATCH_MARKER'"
    echo "   File location: $PATCH_FILE"
    echo ""
    echo "   To fix:"
    echo "   1. Run: ./scripts/apply_patches.sh"
    echo "   2. Or manually apply patch from: patches/tor-0.4.8.19/src/lib/crypt_ops/crypto_rand_fast.c.patched"
    echo ""
    exit 1
fi

# Show patch location
echo "✅ iOS patch verified!"
echo "   File: $PATCH_FILE"
echo "   Patch found at line(s):"
grep -n "$PATCH_MARKER" "$PATCH_FILE" | head -1 | sed 's/^/      /'
echo ""
echo "🚀 Safe to proceed with build!"
echo ""

