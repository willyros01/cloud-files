#!/usr/bin/env bash
# Persistent Android APK signing for the isolated cloud-files/android branch.
# Secrets MUST be supplied by GitHub Actions. No fallback to a new debug key.
set -euo pipefail
umask 077

: "${CLOUDFILES_SIGNING_KEYSTORE_BASE64:?Missing GitHub secret CLOUDFILES_SIGNING_KEYSTORE_BASE64}"
: "${CLOUDFILES_SIGNING_PASSWORD:?Missing GitHub secret CLOUDFILES_SIGNING_PASSWORD}"

APP="android/app"
test -f "$APP/build.gradle"
STORE="$APP/cloudfiles-signing.p12"
printf '%s' "$CLOUDFILES_SIGNING_KEYSTORE_BASE64" | base64 --decode > "$STORE"
chmod 600 "$STORE"
test -s "$STORE"

if ! keytool -list -keystore "$STORE" -storetype PKCS12 \
     -storepass "$CLOUDFILES_SIGNING_PASSWORD" -alias cloudfiles >/dev/null 2>&1; then
  echo "::error title=Android signing invalid::Secret keystore/password/alias mismatch"
  exit 1
fi

cat > "$APP/cloudfiles-sign.gradle" <<'GRADLE'
android {
    signingConfigs {
        cloudfilesPersistent {
            storeFile file("cloudfiles-signing.p12")
            storePassword System.getenv("CLOUDFILES_SIGNING_PASSWORD")
            keyAlias "cloudfiles"
            keyPassword System.getenv("CLOUDFILES_SIGNING_PASSWORD")
            storeType "PKCS12"
        }
    }
    buildTypes {
        debug {
            signingConfig signingConfigs.cloudfilesPersistent
        }
    }
}
GRADLE

if ! grep -Fq 'apply from: "cloudfiles-sign.gradle"' "$APP/build.gradle"; then
  printf '\napply from: "cloudfiles-sign.gradle"\n' >> "$APP/build.gradle"
fi
echo "Stable Android signing configuration verified; private key stays in runner."
