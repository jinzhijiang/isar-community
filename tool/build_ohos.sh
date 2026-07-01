#!/bin/bash

# Build script for OpenHarmony (ohos) platform
# OpenHarmony is based on Linux, so we can use similar approach to Android

# Always run from the isar-community repo root (so relative paths are stable)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISAR_COMMUNITY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ISAR_COMMUNITY_ROOT"

# Detect host OS
if [[ "$(uname -s)" == "Darwin" ]]; then
    export NDK_HOST_TAG="darwin-x86_64"
elif [[ "$(uname -s)" == "Linux" ]]; then
    export NDK_HOST_TAG="linux-x86_64"
else
    echo "Unsupported OS."
    exit 1
fi

# Check for OpenHarmony NDK
OHOS_NDK=${OHOS_NDK_HOME:-${OHOS_SDK_HOME:-"/Volumes/cc/Library/ohos/OpenHarmony/Sdk/20/native"}}

# If OHOS NDK is not set or doesn't exist, try to use standard Linux cross-compilation
if [ -z "$OHOS_NDK" ] || [ ! -d "$OHOS_NDK" ]; then
    echo "⚠️  OpenHarmony NDK not found. Using standard Linux cross-compilation."
    echo "   This may work if OpenHarmony's system libraries are compatible."
    echo ""
    
    # Use standard Linux aarch64 target
    cd packages/isar_core_ffi
    
    echo "Building for OpenHarmony arm64 (using Linux target)"
    echo "Installing Rust toolchain if needed..."
    
    # Install Rust if not available
    if ! command -v rustc &> /dev/null; then
        echo "Rust not found. Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Add the target
    rustup target add aarch64-unknown-linux-gnu
    
    # Try to build
    echo "Building libisar.so for OpenHarmony..."
    cargo build --target aarch64-unknown-linux-gnu --release --features ohos
    
    if [ $? -eq 0 ]; then
        # Copy the built library
        OUTPUT_DIR="../../packages/isar_community_flutter_libs/ohos/libs/arm64-v8a"
        mkdir -p "$OUTPUT_DIR"
        cp "../../target/aarch64-unknown-linux-gnu/release/libisar.so" "$OUTPUT_DIR/libisar.so"
        echo "✅ Successfully built libisar.so for OpenHarmony"
        echo "   Output: $OUTPUT_DIR/libisar.so"
    else
        echo "❌ Build failed. You may need to install OpenHarmony NDK."
        echo "   Set OHOS_NDK_HOME environment variable to your OpenHarmony NDK path."
        exit 1
    fi
else
    echo "Using OpenHarmony NDK at: $OHOS_NDK"
    
    # Find the compiler directory
    COMPILER_DIR="$OHOS_NDK/llvm/bin"
    SYSROOT="$OHOS_NDK/sysroot"
    
    if [ ! -d "$COMPILER_DIR" ]; then
        echo "❌ Could not find compiler in OpenHarmony NDK"
        echo "   Expected at: $COMPILER_DIR"
        exit 1
    fi
    
    if [ ! -d "$SYSROOT" ]; then
        echo "❌ Could not find sysroot in OpenHarmony NDK"
        echo "   Expected at: $SYSROOT"
        exit 1
    fi
    
    export PATH="$COMPILER_DIR:$PATH"
    
    # Set up cross-compilation tools for OpenHarmony
    # OpenHarmony uses aarch64-unknown-linux-ohos target
    CC="$COMPILER_DIR/aarch64-unknown-linux-ohos-clang"
    CXX="$COMPILER_DIR/aarch64-unknown-linux-ohos-clang++"
    AR="$COMPILER_DIR/llvm-ar"
    
    # Find llvm-ar
    if [ ! -x "$AR" ]; then
        AR="$COMPILER_DIR/ar"
    fi
    
    if [ ! -x "$CC" ]; then
        echo "❌ Could not find OpenHarmony compiler: $CC"
        exit 1
    fi
    
    if [ ! -x "$AR" ]; then
        echo "❌ Could not find OpenHarmony archiver: $AR"
        exit 1
    fi
    
    echo "Compiler: $CC"
    echo "Archiver: $AR"
    echo "Sysroot: $SYSROOT"
    
    # Set up environment variables for Rust cross-compilation
    # We use aarch64-unknown-linux-gnu target but with OpenHarmony toolchain
    export CC_aarch64_unknown_linux_gnu="$CC"
    export AR_aarch64_unknown_linux_gnu="$AR"
    export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER="$CC"
    export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_AR="$AR"
    
    # Set sysroot for the compiler
    export CFLAGS_aarch64_unknown_linux_gnu="--sysroot=$SYSROOT -target aarch64-unknown-linux-ohos"
    export CXXFLAGS_aarch64_unknown_linux_gnu="--sysroot=$SYSROOT -target aarch64-unknown-linux-ohos"
    
    # Set sysroot for bindgen (used by mdbx-sys)
    export BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_linux_gnu="--sysroot=$SYSROOT -target aarch64-unknown-linux-ohos -I$SYSROOT/usr/include"
    
    # Set linker flags for OpenHarmony
    # OpenHarmony doesn't use libgcc_s, so we need to remove it from the link command
    export RUSTFLAGS="-C link-arg=--sysroot=$SYSROOT -C link-arg=-target -C link-arg=aarch64-unknown-linux-ohos -C link-arg=-L$SYSROOT/usr/lib/aarch64-linux-ohos -C link-arg=-Wl,--as-needed"
    
    cd packages/isar_core_ffi
    
    echo "Building for OpenHarmony arm64 with NDK"
    
    # Install Rust if not available
    if ! command -v rustc &> /dev/null; then
        echo "Rust not found. Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Add the target
    rustup target add aarch64-unknown-linux-gnu
    
    # Build with OpenHarmony toolchain
    echo "Starting build..."
    cargo build --target aarch64-unknown-linux-gnu --release --features ohos
    
    if [ $? -eq 0 ]; then
        OUTPUT_DIR="../../packages/isar_community_flutter_libs/ohos/libs/arm64-v8a"
        mkdir -p "$OUTPUT_DIR"
        cp "../../target/aarch64-unknown-linux-gnu/release/libisar.so" "$OUTPUT_DIR/libisar.so"
        
        # Build libgcc_s stub library from the repo source (single source of truth)
        # Note: pwd is packages/isar_core_ffi at this point
        STUB_SOURCE="$(pwd)/libgcc_s_stub.c"
        if [ ! -f "$STUB_SOURCE" ]; then
            echo "❌ Missing stub source: $STUB_SOURCE"
            exit 1
        fi
        
        # Compile the stub library
        "$CC" --sysroot="$SYSROOT" -target aarch64-unknown-linux-ohos -shared -fPIC -o "$OUTPUT_DIR/libgcc_s.so.1" "$STUB_SOURCE"
        if [ $? -eq 0 ]; then
            echo "   Created libgcc_s.so.1 stub library (unwind/TLS symbols)"
        else
            echo "   ⚠️  Failed to create libgcc_s stub, using existing one if available"
        fi
        
        echo ""
        echo "✅ Successfully built libisar.so for OpenHarmony"
        echo "   Output: $OUTPUT_DIR/libisar.so"
        echo "   File size: $(ls -lh "$OUTPUT_DIR/libisar.so" | awk '{print $5}')"
    else
        echo "❌ Build failed"
        exit 1
    fi
fi

