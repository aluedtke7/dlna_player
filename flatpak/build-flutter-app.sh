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
flutter clean
flutter gen-l10n
flutter build linux --release

cd build/linux/x64/release/bundle || exit 1
tar -czaf $archiveName ./*
mv $archiveName "$baseDir"/
popd

flatpak-builder --force-clean build-dir app.yml --repo=repo
flatpak build-bundle repo de.luedtke.dlna_player.flatpak de.luedtke.dlna_player
