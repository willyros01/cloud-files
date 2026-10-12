#!/usr/bin/env bash
# Cloud Files Fire OS Android test APK; permanently signed, not a production release.
set -euo pipefail
node --version
node build/test-android.cjs
npm install --no-audit --no-fund
npx cap add android
npx cap sync android
bash build/android-native.sh
java build/AndroidIcons.java android/app/src/main/res

# Use monotonic GitHub run_number for reliable Android update ordering.
export CLOUD_VERSION_CODE="${GITHUB_RUN_NUMBER:-1}"
python3 - <<'PY'
import os, pathlib, re
file=pathlib.Path('android/app/build.gradle')
s=file.read_text()
assert re.search(r'(?m)^\s*versionCode\s+\d+\s*$',s), 'Unexpected Gradle versionCode'
n=int(os.environ['CLOUD_VERSION_CODE'])
assert 1<=n<=2100000000
s=re.sub(r'(?m)^(\s*versionCode\s+)\d+(\s*)$',lambda m:m.group(1)+str(n)+m.group(2),s,count=1)
file.write_text(s)
print('Android versionCode:', n)
PY

bash build/android-sign.sh
trap 'rm -f android/app/cloudfiles-signing.p12 android/app/cloudfiles-sign.gradle' EXIT
cd android
chmod +x ./gradlew
./gradlew --no-daemon assembleDebug

APK=app/build/outputs/apk/debug/app-debug.apk
test -s "$APK"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
test -n "$SDK"
SIGNER="$(find "$SDK/build-tools" -name apksigner -type f | sort -V | tail -1)"
test -n "$SIGNER"
"$SIGNER" verify --verbose --print-certs "$APK"
ACTUAL="$("$SIGNER" verify --print-certs "$APK" | sed -n 's/^.*certificate SHA-256 digest: *//p' | head -1 | tr 'A-F' 'a-f')"
EXPECTED="$(keytool -list -v -keystore app/cloudfiles-signing.p12 -storetype PKCS12 -storepass "$CLOUDFILES_SIGNING_PASSWORD" -alias cloudfiles | sed -n 's/^[[:space:]]*SHA256: *//p' | head -1 | tr -d ':' | tr 'A-F' 'a-f')"
test -n "$ACTUAL" && test "$ACTUAL" = "$EXPECTED" || {
  echo "::error title=Signer mismatch::Cloud Files APK signer differs from configured permanent key"
  exit 1
}
echo "Verified Cloud Files APK certificate SHA256: $ACTUAL"
sha256sum "$APK"
