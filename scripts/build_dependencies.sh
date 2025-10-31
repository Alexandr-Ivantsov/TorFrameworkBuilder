#!/bin/bash
# build_dependencies.sh - Build dependencies if they don't exist
# This script checks if OpenSSL, Libevent, and XZ are built
# and builds them if missing (for both device and simulator)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🧰 Ensuring build toolchain (autoconf/automake/libtool/pkg-config)..."

NEEDED_TOOLS=(autoconf automake libtool pkg-config)
MISSING_TOOLS=()

for tool in "${NEEDED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "   Missing tools: ${MISSING_TOOLS[*]}"
    if command -v brew >/dev/null 2>&1; then
        echo "   Installing via Homebrew..."
        export HOMEBREW_NO_AUTO_UPDATE=1
        brew install "${MISSING_TOOLS[@]}"
    else
        echo "❌ Homebrew not found. Please install the following tools manually: ${MISSING_TOOLS[*]}"
        exit 1
    fi
else
    echo "✅ Build toolchain already present"
fi

echo "🔍 ========================================"
echo "🔍 CHECKING DEPENDENCIES"
echo "🔍 ========================================"
echo ""

# Check device dependencies
OPENSSL_DEVICE="output/openssl/lib/libssl.a"
LIBEVENT_DEVICE="output/libevent/lib/libevent.a"
XZ_DEVICE="output/xz/lib/liblzma.a"

MISSING_DEVICE=false

if [ ! -f "$OPENSSL_DEVICE" ]; then
    echo "❌ OpenSSL for device not found: $OPENSSL_DEVICE"
    MISSING_DEVICE=true
else
    echo "✅ OpenSSL for device: $OPENSSL_DEVICE"
fi

if [ ! -f "$LIBEVENT_DEVICE" ]; then
    echo "❌ Libevent for device not found: $LIBEVENT_DEVICE"
    MISSING_DEVICE=true
else
    echo "✅ Libevent for device: $LIBEVENT_DEVICE"
fi

if [ ! -f "$XZ_DEVICE" ]; then
    echo "❌ XZ for device not found: $XZ_DEVICE"
    MISSING_DEVICE=true
else
    echo "✅ XZ for device: $XZ_DEVICE"
fi

# Check simulator dependencies
OPENSSL_SIMULATOR="output/openssl-simulator/lib/libssl.a"
LIBEVENT_SIMULATOR="output/libevent-simulator/lib/libevent.a"
XZ_SIMULATOR="output/xz-simulator/lib/liblzma.a"

MISSING_SIMULATOR=false

if [ ! -f "$OPENSSL_SIMULATOR" ]; then
    echo "❌ OpenSSL for simulator not found: $OPENSSL_SIMULATOR"
    MISSING_SIMULATOR=true
else
    echo "✅ OpenSSL for simulator: $OPENSSL_SIMULATOR"
fi

if [ ! -f "$LIBEVENT_SIMULATOR" ]; then
    echo "❌ Libevent for simulator not found: $LIBEVENT_SIMULATOR"
    MISSING_SIMULATOR=true
else
    echo "✅ Libevent for simulator: $LIBEVENT_SIMULATOR"
fi

if [ ! -f "$XZ_SIMULATOR" ]; then
    echo "❌ XZ for simulator not found: $XZ_SIMULATOR"
    MISSING_SIMULATOR=true
else
    echo "✅ XZ for simulator: $XZ_SIMULATOR"
fi

echo ""

# Build missing dependencies
if [ "$MISSING_DEVICE" = true ]; then
    echo "🔨 Building missing device dependencies..."
    echo ""
    
    if [ ! -f "$OPENSSL_DEVICE" ]; then
        echo "📦 Building OpenSSL for device..."
        bash scripts/build_openssl.sh
    fi
    
    if [ ! -f "$LIBEVENT_DEVICE" ]; then
        echo "📦 Building Libevent for device..."
        bash scripts/build_libevent.sh
    fi
    
    if [ ! -f "$XZ_DEVICE" ]; then
        echo "📦 Building XZ for device..."
        bash scripts/build_xz.sh
    fi
    
    echo "✅ Device dependencies built!"
    echo ""
fi

if [ "$MISSING_SIMULATOR" = true ]; then
    echo "🔨 Building missing simulator dependencies..."
    echo ""
    
    if [ ! -f "$OPENSSL_SIMULATOR" ]; then
        echo "📦 Building OpenSSL for simulator..."
        bash scripts/build_openssl_simulator.sh
    fi
    
    if [ ! -f "$LIBEVENT_SIMULATOR" ]; then
        echo "📦 Building Libevent for simulator..."
        bash scripts/build_libevent_simulator.sh
    fi
    
    if [ ! -f "$XZ_SIMULATOR" ]; then
        echo "📦 Building XZ for simulator..."
        bash scripts/build_xz_simulator.sh
    fi
    
    echo "✅ Simulator dependencies built!"
    echo ""
fi

if [ "$MISSING_DEVICE" = false ] && [ "$MISSING_SIMULATOR" = false ]; then
    echo "✅ All dependencies are present!"
    echo "   No build needed."
    echo ""
fi

echo "🚀 Ready to build Tor!"
echo ""

