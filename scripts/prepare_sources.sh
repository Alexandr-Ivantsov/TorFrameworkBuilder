#!/bin/bash
# prepare_sources.sh - Prepare Sources/ directory for SPM/Tuist

set -e

echo "📦 ========================================"
echo "📦 PREPARING Sources/ FOR SPM/TUIST"
echo "📦 ========================================"
echo ""

cd "$(dirname "$0")/.."

# ====================================
# STEP 1: Create Sources/Tor structure
# ====================================

echo "📁 Step 1: Creating Sources/Tor structure..."

mkdir -p Sources/Tor/include
echo "✅ Sources/Tor/include created"

# ====================================
# STEP 2: Copy tor-ios-fixed to Sources/Tor/
# ====================================

echo ""
echo "📋 Step 2: Copying tor-ios-fixed to Sources/Tor/..."

if [ ! -d "tor-ios-fixed" ]; then
    echo "❌ ERROR: tor-ios-fixed/ not found!"
    echo "   Run: ./scripts/fix_conflicts.sh first"
    exit 1
fi

# Remove old copy if exists
rm -rf Sources/Tor/tor-ios-fixed

# Copy tor-ios-fixed
cp -R tor-ios-fixed Sources/Tor/
echo "✅ Copied tor-ios-fixed to Sources/Tor/"

# ====================================
# STEP 3: Ensure orconfig.h exists
# ====================================

echo ""
echo "🔧 Step 3: Checking orconfig.h..."

if [ ! -f "Sources/Tor/tor-ios-fixed/orconfig.h" ]; then
    echo "⚠️  orconfig.h not found, checking if it exists elsewhere..."
    
    # Try to find orconfig.h
    if [ -f "tor-ios-fixed/orconfig.h" ]; then
        echo "✅ Found in tor-ios-fixed/, copying..."
        cp tor-ios-fixed/orconfig.h Sources/Tor/tor-ios-fixed/orconfig.h
    else
        echo "❌ ERROR: orconfig.h not found!"
        echo "   Please create Sources/Tor/tor-ios-fixed/orconfig.h manually"
        exit 1
    fi
else
    echo "✅ orconfig.h exists"
fi

# ====================================
# STEP 4: Create include/tor.h
# ====================================

echo ""
echo "📝 Step 4: Creating include/tor.h..."

cat > Sources/Tor/include/tor.h << 'EOF'
#ifndef TOR_H
#define TOR_H

// Public Tor API header
// This is a minimal header for the Tor library

#ifdef __cplusplus
extern "C" {
#endif

// Tor will be initialized and controlled via TorWrapper
// This header is just for SPM module requirements

#ifdef __cplusplus
}
#endif

#endif /* TOR_H */
EOF

echo "✅ include/tor.h created"

# ====================================
# STEP 5: Summary
# ====================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sources/ PREPARATION COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📂 Structure:"
echo "   Sources/"
echo "   └── Tor/"
echo "       ├── tor-ios-fixed/       (Tor source code)"
echo "       │   ├── orconfig.h      (iOS config)"
echo "       │   └── src/            (Tor sources)"
echo "       └── include/"
echo "           └── tor.h           (Public header)"
echo ""
echo "📊 Statistics:"
echo "   - Tor source files: $(find Sources/Tor/tor-ios-fixed/src -name "*.c" 2>/dev/null | wc -l | tr -d ' ')"
echo "   - Tor header files: $(find Sources/Tor/tor-ios-fixed/src -name "*.h" 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "✅ Ready for git add and commit!"
echo ""

