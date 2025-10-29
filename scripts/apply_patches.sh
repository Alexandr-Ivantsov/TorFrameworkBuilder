#!/bin/bash
# apply_patches.sh - Apply iOS patches to Tor source code
# This script MUST be run BEFORE compilation

set -e  # Exit on any error

echo "🔧 ========================================"
echo "🔧 APPLYING TOR iOS PATCHES"
echo "🔧 ========================================"
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
    echo "   Patches will be applied later when sources are available"
    exit 0
fi

echo "✅ Found crypto_rand_fast.c file(s):"
echo "$CRYPTO_FILES" | sed 's/^/   - /'
echo ""

# ====================================
# STEP 2: Check if patched file exists
# ====================================

PATCHED_FILE="patches/tor-0.4.8.19/src/lib/crypt_ops/crypto_rand_fast.c.patched"

if [ ! -f "$PATCHED_FILE" ]; then
    echo "❌ ERROR: Patched file not found: $PATCHED_FILE"
    echo "   Run: git checkout patches/ to restore"
    exit 1
fi

echo "✅ Patched file found: $PATCHED_FILE"
echo ""

# ====================================
# STEP 3: Apply patch to each file
# ====================================

echo "🔧 Step 3: Applying patches..."
echo ""

PATCHED_COUNT=0
ALREADY_PATCHED_COUNT=0

while IFS= read -r file; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 Processing: $file"
    
    # Check if already patched
    if grep -q "iOS PATCH\|Using memory with INHERIT_RES_KEEP\|Platform does not support non-inheritable memory" "$file" 2>/dev/null; then
        echo "   ✅ Already patched - skipping"
        ALREADY_PATCHED_COUNT=$((ALREADY_PATCHED_COUNT + 1))
    else
        echo "   🔧 Applying patch..."
        
        # Backup original
        cp "$file" "$file.bak"
        
        # Copy patched version
        cp "$PATCHED_FILE" "$file"
        
        # Verify patch was applied
        if grep -q "iOS PATCH\|Using memory with INHERIT_RES_KEEP\|Platform does not support non-inheritable memory" "$file"; then
            echo "   ✅✅✅ Patch applied successfully!"
            rm -f "$file.bak"
            PATCHED_COUNT=$((PATCHED_COUNT + 1))
        else
            echo "   ❌ VERIFICATION FAILED! Restoring backup..."
            mv "$file.bak" "$file"
            exit 1
        fi
    fi
    echo ""
done <<< "$CRYPTO_FILES"

# ====================================
# STEP 4: Summary
# ====================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PATCH APPLICATION COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo "   - Files patched now:     $PATCHED_COUNT"
echo "   - Files already patched: $ALREADY_PATCHED_COUNT"
echo "   - Total files:           $((PATCHED_COUNT + ALREADY_PATCHED_COUNT))"
echo ""

if [ $PATCHED_COUNT -gt 0 ]; then
    echo "🎉 Successfully patched $PATCHED_COUNT file(s)!"
elif [ $ALREADY_PATCHED_COUNT -gt 0 ]; then
    echo "✅ All files were already patched"
else
    echo "⚠️  No files needed patching"
fi

echo ""
echo "✅ Ready for compilation!"
echo ""

