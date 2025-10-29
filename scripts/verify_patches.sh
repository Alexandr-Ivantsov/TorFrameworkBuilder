#!/bin/bash
# verify_patches.sh - Verify iOS patches are applied BEFORE compilation
# This script MUST be run BEFORE compilation to ensure patches are present

set -e  # Exit on any error

echo "🔍 ========================================"
echo "🔍 VERIFYING TOR iOS PATCHES"
echo "🔍 ========================================"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# ====================================
# STEP 1: Find all crypto_rand_fast.c files
# ====================================

echo "📂 Step 1: Searching for crypto_rand_fast.c files..."

CRYPTO_FILES=$(find . -path "*/crypt_ops/crypto_rand_fast.c" -type f 2>/dev/null | grep -v ".build" | grep -v "patches" || true)

if [ -z "$CRYPTO_FILES" ]; then
    echo "⚠️  Warning: No crypto_rand_fast.c files found"
    echo "   This may be normal if sources haven't been extracted yet"
    echo "   Skipping verification (patches will be verified later)"
    exit 0
fi

echo "✅ Found crypto_rand_fast.c file(s):"
echo "$CRYPTO_FILES" | sed 's/^/   - /'
echo ""

# ====================================
# STEP 2: Verify each file is patched
# ====================================

echo "🔍 Step 2: Verifying patches..."
echo ""

ALL_VERIFIED=true
VERIFIED_COUNT=0
NOT_PATCHED_COUNT=0

while IFS= read -r file; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 Checking: $file"
    
    # Check for patch markers
    if grep -q "iOS PATCH\|Using memory with INHERIT_RES_KEEP\|Platform does not support non-inheritable memory" "$file" 2>/dev/null; then
        echo "   ✅ VERIFIED: Patch is present!"
        VERIFIED_COUNT=$((VERIFIED_COUNT + 1))
        
        # Show patch location
        echo "   📍 Patch found at lines:"
        grep -n "iOS PATCH\|Using memory with INHERIT_RES_KEEP\|Platform does not support" "$file" | head -3 | sed 's/^/      /'
    else
        echo "   ❌ NOT PATCHED: File is missing the iOS patch!"
        echo ""
        echo "   📄 Content around line 187 (expected patch location):"
        sed -n '180,200p' "$file" 2>/dev/null | nl -v 180 | sed 's/^/      /' || echo "      (file not readable)"
        echo ""
        ALL_VERIFIED=false
        NOT_PATCHED_COUNT=$((NOT_PATCHED_COUNT + 1))
    fi
    echo ""
done <<< "$CRYPTO_FILES"

# ====================================
# STEP 3: Final result
# ====================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$ALL_VERIFIED" = "true" ]; then
    echo "✅✅✅ SUCCESS! ALL FILES VERIFIED!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📊 Summary:"
    echo "   - Files verified:     $VERIFIED_COUNT"
    echo "   - Files NOT patched:  $NOT_PATCHED_COUNT"
    echo ""
    echo "🚀 All patches are applied! Safe to compile!"
    echo ""
    exit 0
else
    echo "❌❌❌ CRITICAL ERROR! VERIFICATION FAILED!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📊 Summary:"
    echo "   - Files verified:     $VERIFIED_COUNT"
    echo "   - Files NOT patched:  $NOT_PATCHED_COUNT"
    echo ""
    echo "🚫 ABORTING BUILD!"
    echo ""
    echo "💡 To fix this issue:"
    echo "   1. Run: ./scripts/apply_patches.sh"
    echo "   2. Re-run verification: ./scripts/verify_patches.sh"
    echo "   3. Then compile"
    echo ""
    exit 1
fi

