#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

rm -rf build Mysnap.app
mkdir -p build Mysnap.app/Contents/MacOS Mysnap.app/Contents/Resources

echo "[1/4] Kompilasi Mysnap.m (target minimum macOS 10.13, universal2 bila toolchain mendukung)..."
COMMON=(-fobjc-arc -O2 -Wall -framework Cocoa -framework Carbon -framework ApplicationServices)
clang "${COMMON[@]}" -target x86_64-apple-macos10.13 Mysnap.m -o build/Mysnap-x86_64
if clang "${COMMON[@]}" -target arm64-apple-macos11 Mysnap.m -o build/Mysnap-arm64 2> build/arm64.log; then
  lipo -create build/Mysnap-x86_64 build/Mysnap-arm64 -output build/Mysnap
  echo "  -> binary universal2: x86_64 (macOS 10.13+) + arm64 (Apple Silicon)"
else
  mv build/Mysnap-x86_64 build/Mysnap
  echo "  -> toolchain tidak mendukung slice arm64; dipakai binary x86_64 saja (tetap target 10.13)"
fi

echo "[2/4] Menyusun bundle Mysnap.app..."
mv build/Mysnap Mysnap.app/Contents/MacOS/Mysnap
printf 'APPL????' > Mysnap.app/Contents/PkgInfo
cat > Mysnap.app/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>Mysnap</string>
  <key>CFBundleName</key>
  <string>Mysnap</string>
  <key>CFBundleDisplayName</key>
  <string>Mysnap</string>
  <key>CFBundleIdentifier</key>
  <string>com.mysnap.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleIconFile</key>
  <string>Mysnap</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.13</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSHumanReadableCopyright</key>
  <string>Mysnap</string>
</dict>
</plist>
PLIST

echo "[3/4] Membuat ikon aplikasi dari assets/logo.png..."
ICONSET=build/Mysnap.iconset
mkdir -p "$ICONSET"
sips -z 16 16     assets/logo.png --out "$ICONSET/icon_16x16.png"     > /dev/null
sips -z 32 32     assets/logo.png --out "$ICONSET/icon_16x16@2x.png"  > /dev/null
sips -z 32 32     assets/logo.png --out "$ICONSET/icon_32x32.png"     > /dev/null
sips -z 64 64     assets/logo.png --out "$ICONSET/icon_32x32@2x.png"  > /dev/null
sips -z 128 128   assets/logo.png --out "$ICONSET/icon_128x128.png"   > /dev/null
sips -z 256 256   assets/logo.png --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256 256   assets/logo.png --out "$ICONSET/icon_256x256.png"   > /dev/null
sips -z 512 512   assets/logo.png --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512 512   assets/logo.png --out "$ICONSET/icon_512x512.png"   > /dev/null
sips -z 1024 1024 assets/logo.png --out "$ICONSET/icon_512x512@2x.png" > /dev/null
iconutil -c icns "$ICONSET" -o Mysnap.app/Contents/Resources/Mysnap.icns

echo "[4/4] Codesign ad-hoc..."
codesign --force --sign - Mysnap.app

echo ""
echo "Selesai: Mysnap.app siap dijalankan."
echo "Jalankan langsung:   open Mysnap.app"
echo "Instal permanen:     cp -R Mysnap.app /Applications/   (lalu cari 'Mysnap' via Spotlight)"
echo "Catatan jujur: skrip ini hanya mengompilasi dengan deployment target 10.13;"
echo "jika dijalankan di macOS lebih baru, hasilnya BELUM berarti teruji di High Sierra."
