#!/bin/sh
# build.sh --
#
#	Builds Tkabber for Android: an APK of Tk for Android (the android
#	branch of https://github.com/pounceandmiss/tk-wayland) whose
#	application is Tkabber, with tcllib, BWidget and tcltls (OpenSSL).
#
#	android/build.sh TOP
#
#	TOP is the directory of the Android build of Tk: it holds the Tk
#	sources in tk, the Tcl sources in tcl, the Android SDK in android-sdk,
#	and the build directories in build (see tk/android/README.md). The
#	build runs in the tk-android-build image (tk/android/build/Dockerfile),
#	with TOP mounted at the same path. ANDROID_ABI is arm64-v8a (phones,
#	the default) or x86_64 (the emulator). The APK is
#	TOP/build/tkabber-$ANDROID_ABI/tkabber.apk.

set -e
here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
TOP=$(cd "${1:?usage: android/build.sh TOP}" && pwd)
ABI=${ANDROID_ABI:-arm64-v8a}
W=$TOP/build/tkabber-$ABI
SRC=$TOP/build/tkabber-src
MAKEFILE=$TOP/tk/android/build/Makefile

run() {
    docker run --rm -i -u "$(id -u):$(id -g)" -e HOME=/tmp \
	-v "$TOP:$TOP" -w "$W" tk-android-build "$@"
}

# The sources of the libraries, from their upstreams, checked.

mkdir -p "$SRC" "$W"
fetch() {
    f=$SRC/$(basename "$1")
    if [ ! -f "$f" ]; then
	curl -fsSL -o "$f.part" "$1"
	mv "$f.part" "$f"
    fi
    echo "$2  $f" | sha256sum -c --quiet
    tar xzf "$f" -C "$SRC"
}
fetch https://github.com/openssl/openssl/releases/download/openssl-3.6.5/openssl-3.6.5.tar.gz \
    a2157c2830efdec3788939b00c9b0638306d3f0bbb76dc4832ee503bb397df98
fetch https://core.tcl-lang.org/tcltls/uv/tcltls2.0.1.tar.gz \
    afffeb5de1978f47745db4804c1dfdcd6605ceac32e324fe8bbe49843de0baae
fetch https://core.tcl-lang.org/tcllib/uv/tcllib-2.0.tar.gz \
    590263de0832ac801255501d003441a85fb180b8ba96265d50c4a9f92fde2534
fetch https://downloads.sourceforge.net/project/tcllib/BWidget/1.10.1/bwidget-1.10.1.tar.gz \
    4aea02f38cf92fa4aa44732d4ed98648df839e6537d6f0417c3fe18e1a34f880

# Tcl and Tk, then OpenSSL and tcltls, which need Tcl.

rm -rf "$W/android"
cp -r "$here" "$W/android"
run make -f "$MAKEFILE" ANDROID_ABI="$ABI" BUILD="$W" tk
run make -f "$W/android/tls.mk" ANDROID_ABI="$ABI" BUILD="$W" SRC="$SRC"

# The application: main.tcl, Tkabber (with TclXMPP) and the libraries.

app=$W/app
rm -rf "$app"
mkdir -p "$app/lib/tls" "$app/tkabber"
cp "$here/main.tcl" "$app/"
(cd "$repo" && tar cf - --exclude=./android --exclude=./.git \
    --exclude=./README.md .) | tar xf - -C "$app/tkabber"
cp "$here/tls/pkgIndex.tcl" "$here/tls/android.tcl" \
    "$SRC/tcltls2.0.1/library/tls.tcl" "$app/lib/tls/"
cp -r "$SRC/bwidget-1.10.1" "$app/lib/bwidget1.10.1"
run sh -c "cd $SRC/tcllib-2.0 && $TOP/build/android-host/bin/tclsh9.1 \
    installer.tcl -no-wait -no-gui -no-html -no-nroff -no-examples \
    -no-apps -pkg-path $app/lib/tcllib2.0" > "$W/tcllib-install.log"

# The APK of Tk with the application and tcltls linked in, as the package
# tk.tkabber, then again with the name and icon of Tkabber.

rm -rf "$W/scripts" "$W/scripts.zip" "$W/apk" "$W/tk.apk"
run make -f "$MAKEFILE" ANDROID_ABI="$ABI" BUILD="$W" APP_DIR="$app" \
    "TEST_LIBS=$W/tlsinit.o $W/tcltls/libtcl9tls2.0.1.a $W/tcl/libtclstub.a $W/ssl/lib/libssl.a $W/ssl/lib/libcrypto.a" \
    "LINK_FLAGS=--rename-manifest-package tk.tkabber" apk

res=$W/res
rm -rf "$res"
cp -r "$TOP/tk/android/res" "$res"
cp -r "$here/res/"* "$res/"
sed -e 's/android:label="Wish"/android:label="Tkabber"/g' \
    -e 's|<application|<application android:icon="@mipmap/ic_launcher"|' \
    "$TOP/tk/android/AndroidManifest.xml" > "$W/AndroidManifest.xml"
run sh -c "
    set -e
    BT=\$(ls -d $TOP/android-sdk/build-tools/* | sort | tail -1)
    JAR=\$(ls $TOP/android-sdk/platforms/android-*/android.jar | sort | tail -1)
    rm -f tkabber-res.zip tkabber-base.apk tkabber-aligned.apk tkabber.apk
    \$BT/aapt2 compile --dir $res -o tkabber-res.zip
    \$BT/aapt2 link -o tkabber-base.apk --manifest AndroidManifest.xml \
	tkabber-res.zip -I \$JAR --min-sdk-version 30 \
	--target-sdk-version 35 --rename-manifest-package tk.tkabber
    (cd apk && zip -q -0 -r ../tkabber-base.apk lib)
    zip -q tkabber-base.apk classes.dex
    \$BT/zipalign -P 16 -f 4 tkabber-base.apk tkabber-aligned.apk
    \$BT/apksigner sign --ks $TOP/build/android-debug.keystore \
	--ks-pass pass:android --out tkabber.apk tkabber-aligned.apk
"
echo "$W/tkabber.apk"
