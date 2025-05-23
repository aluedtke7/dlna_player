FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Europe apt-get -y install tzdata

# Install tree and Flutter dependencies
RUN apt-get -y install tree curl file git unzip xz-utils zip clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
# Install GStreamer dependencies (needed by audioplayers)
RUN apt-get -y install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
# Install app-specific dependencies
RUN apt-get -y install keybinder-3.0 appindicator3-0.1 libappindicator3-1 libappindicator3-dev
# Prepare environment for building Flatpak
RUN apt-get -y install flatpak flatpak-builder
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
RUN flatpak install -y org.freedesktop.Sdk/x86_64/23.08
RUN flatpak install -y org.freedesktop.Platform/x86_64/23.08
RUN flatpak install -y flathub org.freedesktop.appstream-glib

RUN useradd -m -s /bin/bash builder

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /home/builder/flutter
RUN git config --global --add safe.directory /home/builder/flutter
ENV PATH="$PATH:/home/builder/flutter/bin"
RUN flutter upgrade
RUN chown -R builder:builder /home/builder/flutter
