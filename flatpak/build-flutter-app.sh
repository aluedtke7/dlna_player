#!/bin/bash
set -e
set -x

projectName=DLNA_Player
archiveName=$projectName-Linux-Portable.tar.gz
baseDir=$(pwd)

pushd .

cd ..

# Build Flutter app
flutter --disable-analytics
flutter --version
flutter clean
rm pubspec.lock
flutter pub get

# Patch nativeapi plugin for compatibility with older GLib versions (e.g. Ubuntu 22.04)
# G_APPLICATION_DEFAULT_FLAGS was introduced in GLib 2.74
PLUGIN_FILE="linux/flutter/ephemeral/.plugin_symlinks/cnativeapi/cxx_impl/src/platform/linux/application_linux.cpp"
if [ -f "$PLUGIN_FILE" ]; then
    echo "Patching $PLUGIN_FILE for GLib compatibility..."
    sed -i 's/G_APPLICATION_DEFAULT_FLAGS/G_APPLICATION_FLAGS_NONE/g' "$PLUGIN_FILE"
fi

flutter gen-l10n
flutter build linux --release -v

cd build/linux/x64/release/bundle || exit 1
tar -czaf $archiveName ./*
mv $archiveName "$baseDir"/
popd

flatpak-builder --force-clean build-dir app.yml --repo=repo
flatpak build-bundle repo de.luedtke.dlna_player.flatpak de.luedtke.dlna_player
