#!/bin/bash
# Build script for DLNA Player on Linux

set -e

echo "Building DLNA Player for Linux..."

# Clean previous build
echo "Cleaning previous build..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build Linux release
echo "Building Linux release..."
flutter build linux --release

# Create wrapper script for locale fix
BUNDLE_DIR="build/linux/x64/release/bundle"
if [ -f "$BUNDLE_DIR/dlna_player" ]; then
    echo "Creating wrapper script..."
    mv "$BUNDLE_DIR/dlna_player" "$BUNDLE_DIR/dlna_player.bin"
    cat > "$BUNDLE_DIR/dlna_player" << 'WRAPPER'
#!/bin/sh
exec env LC_NUMERIC=C LC_ALL=C "$(dirname "$0")/dlna_player.bin" "$@"
WRAPPER
    chmod +x "$BUNDLE_DIR/dlna_player"
fi

echo "Build complete! Output: $BUNDLE_DIR/"
