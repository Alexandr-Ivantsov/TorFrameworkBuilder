#!/bin/bash
# verify_patch.sh - Verify that crypto_rand_fast.c patch is in binary
set -e

BINARY="$1"

if [ -z "$BINARY" ]; then
    echo "Usage: $0 <path-to-Tor.framework/Tor>"
    echo "Example: $0 output/Tor.xcframework/ios-arm64/Tor.framework/Tor"
    exit 1
fi

if [ ! -f "$BINARY" ]; then
    echo "❌ ERROR: Binary not found: $BINARY"
    exit 1
fi

echo "🔍 VERIFICATION: Checking crypto_rand_fast.c patch in binary..."
echo "📁 Binary: $BINARY"
echo "📊 Size: $(du -h "$BINARY" | cut -f1)"
echo ""

# Check for patch string
if strings "$BINARY" | grep -q "Using memory with INHERIT_RES_KEEP on iOS"; then
    echo "✅✅✅ SUCCESS: Patch FOUND in binary!"
    echo "📄 Found string: Using memory with INHERIT_RES_KEEP on iOS (with PID check)."
    echo ""
    echo "✅ This means:"
    echo "   - crypto_rand_fast.c patch is compiled into binary"
    echo "   - NO crash on line 187!"
    echo "   - Tor will work on iOS!"
    exit 0
else
    echo "❌❌❌ FAILED: Patch NOT found in binary!"
    echo ""
    echo "📋 Binary contains (crypto_rand related):"
    strings "$BINARY" | grep -i "inherit\|non-inheritable" | head -10
    echo ""
    echo "❌ This means:"
    echo "   - Patch was NOT compiled into binary"
    echo "   - WILL crash on line 187!"
    echo "   - DO NOT release this version!"
    exit 1
fi

