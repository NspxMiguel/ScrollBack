#!/bin/bash
# Builds ScrollBack.app (universal binary) into ./build.
set -euo pipefail

cd "$(dirname "$0")"

VERSION="${VERSION:-$(cat VERSION 2>/dev/null || echo 1.0.0)}"
APP="build/ScrollBack.app"
BUNDLE_ID="dev.nspx.ScrollBack"

echo "==> Compiling (release, arm64 + x86_64)"
swift build -c release --arch arm64 --arch x86_64

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/apple/Products/Release/ScrollBack "$APP/Contents/MacOS/ScrollBack"

echo "==> Drawing the icon"
rm -rf build/AppIcon.iconset
swift Tools/makeicon.swift build/AppIcon.iconset >/dev/null
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf build/AppIcon.iconset

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>ScrollBack</string>
    <key>CFBundleDisplayName</key><string>ScrollBack</string>
    <key>CFBundleExecutable</key><string>ScrollBack</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHumanReadableCopyright</key><string>MIT — github.com/NspxMiguel/ScrollBack</string>
    <key>NSSupportsAutomaticTermination</key><false/>
    <key>NSSupportsSuddenTermination</key><false/>
</dict>
</plist>
PLIST

# Ad-hoc signing changes the cdhash on every build, and the app's designated
# requirement IS that hash: macOS treats each build as a different app and
# throws away the Accessibility grant. A local certificate pins the
# requirement to the certificate instead, which does not change, so the grant
# survives future versions. Whoever installs via Homebrew doesn't have that
# certificate, and doesn't need to — ad-hoc there is fine, since the
# permission gets granted fresh at install time either way.
SIGN_ID="NSPX Local Code Signing"
SIGN_KEYCHAIN="$HOME/Library/Keychains/nspx-codesign.keychain-db"
signed_locally=false
if [ -f "$SIGN_KEYCHAIN" ] && security find-identity -p codesigning "$SIGN_KEYCHAIN" 2>/dev/null | grep -q "$SIGN_ID"; then
    echo "==> Signing with $SIGN_ID"
    if codesign --force --deep --sign "$SIGN_ID" --keychain "$SIGN_KEYCHAIN" "$APP" 2>/tmp/scrollback-codesign.log; then
        signed_locally=true
    else
        echo "==> Local identity rejected by codesign ($(tail -1 /tmp/scrollback-codesign.log)), falling back to ad-hoc"
    fi
fi
if [ "$signed_locally" = false ]; then
    echo "==> Signing (ad-hoc)"
    codesign --force --deep --sign - "$APP"
fi

echo "==> Done: $APP ($VERSION)"
