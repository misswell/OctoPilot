#!/bin/zsh
set -euo pipefail

# Produce a distributable, notarized OctoPilot.app + zip.
# Requires:
#   OCTOPILOT_DEVELOPER_ID        "Developer ID Application: Your Name (TEAMID)"
# Notarization credentials - pick one:
#   OCTOPILOT_NOTARY_PROFILE      keychain profile name created via
#                                 `xcrun notarytool store-credentials "PROFILE" \
#                                    --apple-id ID --team-id TEAM --password APPSPECIFIC`
#   OR the three plaintext variables below:
#   OCTOPILOT_APPLE_ID            Apple ID
#   OCTOPILOT_APPLE_PASSWORD      app-specific password
#   OCTOPILOT_TEAM_ID             Team ID

ROOT="${0:A:h:h}"
cd "$ROOT"

: "${OCTOPILOT_DEVELOPER_ID:?Set OCTOPILOT_DEVELOPER_ID to your 'Developer ID Application: Name (TEAMID)' identity}"

NOTARY_ARGS=()
if [[ -n "${OCTOPILOT_NOTARY_PROFILE:-}" ]]; then
    NOTARY_ARGS=(--keychain-profile "$OCTOPILOT_NOTARY_PROFILE")
else
    : "${OCTOPILOT_APPLE_ID:?Set OCTOPILOT_APPLE_ID or OCTOPILOT_NOTARY_PROFILE}"
    : "${OCTOPILOT_APPLE_PASSWORD:?Set OCTOPILOT_APPLE_PASSWORD or OCTOPILOT_NOTARY_PROFILE}"
    : "${OCTOPILOT_TEAM_ID:?Set OCTOPILOT_TEAM_ID or OCTOPILOT_NOTARY_PROFILE}"
    NOTARY_ARGS=(--apple-id "$OCTOPILOT_APPLE_ID" --password "$OCTOPILOT_APPLE_PASSWORD" --team-id "$OCTOPILOT_TEAM_ID")
fi

VERSION="${OCTOPILOT_VERSION:-$("$ROOT/Scripts/version.sh")}"
APP="$ROOT/OctoPilot.app"
ZIP="$ROOT/OctoPilot-$VERSION-macos.zip"

echo "==> Building and signing with Developer ID"
OCTOPILOT_DEVELOPER_ID="$OCTOPILOT_DEVELOPER_ID" ./Scripts/build-app.sh

echo "==> Archiving for notarization"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "==> Submitting to Apple notarization service"
echo "==> Submitting to Apple notarization service"
xcrun notarytool submit "$ZIP" "${NOTARY_ARGS[@]}" --wait

echo "==> Stapling the notarization ticket"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

echo "==> Re-archiving the stapled app"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "==> Verifying"
codesign --verify --deep --strict "$APP"
spctl --assess --type execute --verbose "$APP"

echo "Done. Distributable artifacts:"
echo "  $APP"
echo "  $ZIP"
chmod +x "$ZIP" 2>/dev/null || true
