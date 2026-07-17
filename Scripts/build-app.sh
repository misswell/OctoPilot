#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
cd "$ROOT"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/OctoPilot"
APP="$ROOT/OctoPilot.app"
VERSION="${OCTOPILOT_VERSION:-$("$ROOT/Scripts/version.sh")}"
BUILD_NUMBER="${OCTOPILOT_BUILD_NUMBER:-$(git rev-list --count HEAD)}"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/OctoPilot"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"
ENTITLEMENTS="$ROOT/Resources/OctoPilot.entitlements"
if [[ -n "${OCTOPILOT_DEVELOPER_ID:-}" ]]; then
    codesign --force --deep --options runtime --entitlements "$ENTITLEMENTS" --sign "$OCTOPILOT_DEVELOPER_ID" "$APP"
    echo "Signed with Developer ID: $OCTOPILOT_DEVELOPER_ID"
else
    codesign --force --deep --sign - "$APP"
    echo "Signed ad-hoc (not distributable)"
fi
echo "Built $APP (version $VERSION, build $BUILD_NUMBER)"
