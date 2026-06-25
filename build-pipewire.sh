#!/data/data/com.termux/files/usr/bin/bash
# Cross-compile libpipewire for aarch64-linux-android (bionic)
set -euo pipefail

export PROJECT_DIR="/data/data/com.termux/files/home/pipewire-termux-proot"
export ANDROID_PLATFORM=android-35
export ANDROID_SDK=/data/data/com.termux/files/home/Android
export ANDROID_NDK=$ANDROID_SDK/ndk/29.0.14206865
export TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-aarch64
export SYSROOT=$TOOLCHAIN/sysroot
export TARGET=aarch64-linux-android
export API=35
export AR=$TOOLCHAIN/bin/llvm-ar
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
export PKG_CONFIG_PATH="/data/data/com.termux/files/usr/lib/pkgconfig"
export CFLAGS+=" -Dindex=strchr -Drindex=strrchr"

TERMUX_PREFIX="/data/data/com.termux/files/usr"

# Copy new source files from patches/
cp $PROJECT_DIR/patches/reallocarray.c $PROJECT_DIR/src/pipewire/
cp $PROJECT_DIR/patches/reallocarray.c $PROJECT_DIR/src/modules/
cp $PROJECT_DIR/patches/*.c $PROJECT_DIR/src/modules/
cp $PROJECT_DIR/patches/module-protocol-pulse/* $PROJECT_DIR/src/modules/module-protocol-pulse/modules/
cp $PROJECT_DIR/patches/*.cpp $PROJECT_DIR/src/modules
echo "Module source files copied"

# Apply patches
cd "$PROJECT_DIR"
for patchfile in "$PROJECT_DIR"/patches/0*.patch; do
    echo "Checking patch: $(basename "$patchfile")"
    if patch -Np1 --dry-run < "$patchfile" >/dev/null 2>&1; then
        echo "Applying patch: $(basename "$patchfile")"
        if ! patch -Np1 < "$patchfile"; then
            echo "ERROR: patch $(basename "$patchfile") failed"
            exit 1
        fi
    else
        echo "Skipping already applied patch: $(basename "$patchfile")"
    fi
done

# Clean previous build
rm -rf "$PROJECT_DIR/builddir"

# Configure
mkdir -p "$PROJECT_DIR/builddir/install"
cd "$PROJECT_DIR"

sed -i "s/'-Werror=strict-prototypes',//" meson.build

meson setup builddir \
--cross-file ./android-arm64.txt \
--prefix="$TERMUX_PREFIX" \
-Dauto_features=disabled \
-Dspa-plugins=enabled \
-Dsupport=enabled \
-Ddbus=disabled \
-Dflatpak=disabled \
-Dpipewire-jack=disabled \
-Dpipewire-v4l2=disabled \
-Dlegacy-rtkit=false \
-Djack-devel=false \
-Dtests=disabled \
-Dexamples=disabled \
-Daudioconvert=enabled \
-Dgstreamer=disabled \
-Dgstreamer-device-provider=disabled \
-Dalsa=disabled \
-Djack=disabled \
-Dsession-managers=wireplumber \
-Drlimits-install=false \
-Dpam-defaults-install=false \
-Dffmpeg=enabled \
-Dwireplumber:system-lua=true \
-Dwireplumber:system-lua-version=5.4

meson compile -C builddir

meson install -C builddir
