## Cloud Files Fire OS device result — 2026-10-15 current snapshot

**Accepted on physical Fire HD 8 (owner-confirmed 12 Oct):** after installing signed Android build **38314654572** in place, both **Upload → Open iCloud Drive** and **Download → Open iCloud Drive** launched Apple's iCloud Drive in the external Silk browser. The earlier false “No external browser is installed” message was resolved by directly starting the Android VIEW intent rather than relying on `resolveActivity` package visibility. Build, signer verification, Cuberoot publisher **38314899363** and Pages **38314929156** passed as recorded below.

**Not established:** an actual successful iCloud upload/download, local Files picker content and metadata, all persistence/settings cases, future APK upgrade acceptance or any App Store/Play release. Do not turn source/build evidence into a device PASS. Native work remains confined to `android`; original `main` web and the private signing key are protected. Preserve the same signing certificate, avoid uninstalling an in-use app, and do not begin another build without explicit owner authorization. This is documentation only.

---


# Cloud Files Android / Fire HD 8 — Development and release record
Date: 2026-10-12. Source app: Cloud Files v1.7.3.

## Branches and protected baseline
- Repository `willyros01/cloud-files`. Branch `main` contains the original GitHub Pages web app and stays unchanged.
- Branch `android` contains the Capacitor Android test app, native adapters, tests, and CI workflow. Do NOT auto-merge to main.
- No new GitHub repository was created.
- Changes to the web app and Android app must preserve *functional equivalence*, using platform adapters as needed. Do not blindly merge web-specific code into native app.
- The site `willyros01/Cuberoot` now hosts a same-origin public snapshot at `/cloud-files/`, with Cloud Files listed and described on its homepage; no GitHub repository URL is exposed on the app's Open link.

## What the Cloud Files app actually does
- Cloud Files is a lightweight Fire tablet portal to Apple's iCloud Drive and to local files. It DOES NOT store, sync, or upload users' private iCloud contents itself.
- For Upload and Download, the native Android adapter `CloudFilesLinksPlugin.openICloud` opens Apple's `https://www.icloud.com/iclouddrive/` in an external browser (normally Silk), using a fixed Android VIEW intent. It does not embed Apple sign-in in the Cloud Files WebView or control Apple's download destination.
- Local Files uses the Android system file picker and displays selected file metadata (no application-maintained recent file list). Grid/list and theme settings are device-local; day/night uses local time, optionally geolocation if permitted.
- The native branch includes larger Fire tablet fonts; the existing main web layout is unchanged.
- Launcher icon is generated locally from Java2D into all Android density, round, and adaptive icons.
- App ID: `io.github.willyros01.cloudfiles`; app name: `Cloud Files`. Native package path matches app ID.
- Privacy policy included at `www/privacy.html`.

## Build and permanent signing policy
- `build/android-build.sh` creates Android project in CI, runs `build/test-android.cjs` before compilation, patches versionCode from the monotonic workflow run number, generates plugin and launcher icons, signs APK, and verifies its certificate using `apksigner` and `keytool`.
- `build/android-sign.sh` requires two GitHub Actions repository secrets:
  1. `CLOUDFILES_SIGNING_KEYSTORE_BASE64` — base64 of the UNIQUE private PKCS12 key.
  2. `CLOUDFILES_SIGNING_PASSWORD` — password for the key and its alias `cloudfiles`.
- The build MUST fail closed when either secret is missing/invalid. Never fall back to GitHub runner's ephemeral debug keystore. No private key, password, or base64 material belongs in Git.
- The developer holds privately generated backup files `cl-key.p12`, `cl-pass.txt`, `cl-key64.txt`; these are NOT committed to the repository. Secure copies are required; an unencrypted ZIP must be stored privately. Key fingerprint SHA256: `4ac4eb9b55e91582b0b02820498e1f6ee7208a4d63eca73a2c1bf68c766002ea`.
- Builds produce a *test/debug APK*, not a Google Play production release. Automatic site distribution of successful TEST APKs is authorized; Store release separately gated.
- Workflow: `.github/workflows/android-apk.yml`; result `build/android-last-run.json`; artifact `cloud-files-android-test-apk` with file `app-debug.apk`.

## Website distribution
- Cuberoot workflow `.github/workflows/publish-cloud-files-apk.yml` polls for a successful Android build and writes:
  `downloads/cloud-files.apk`, `downloads/cloud-files.apk.sha256`, `downloads/cloud-files-build.json`.
- Publisher downloads ONLY exact signed APK artifact from the successful GitHub run. Never rebuild from source under an alternative key. Verify Android APK signature and keep an established signer fingerprint unchanged across future builds. Failure leaves existing APK unchanged.
- Cuberoot homepage shows a Cloud Files Android APK download button only when a valid metadata report and same-origin APK exist. The URL includes `?build=<run_id>` for anti-stale cache.
- No source repository path or GitHub repo URL should appear in the public Download/Open URLs.

## Acceptance test on real Fire HD 8 (PENDING until user verifies)
1. Install signed Cloud Files APK on Fire HD 8; check launcher icon, startup, version and terms (none needed for this simple app).
2. Upload → Open iCloud Drive: opens external Silk browser, not captive WebView; sign in to Apple there only. Verify upload workflow through Apple's UI.
3. Return to Cloud Files; Download → Open iCloud Drive: Apple website opens in browser. Download a non-sensitive test file using Apple's controls; confirm Fire Downloads location.
4. Local Files → Browse Local Files: Android file picker; select the test file and verify filename/type/size shown; try grid/list.
5. Verify day/night toggle, app background/foreground, cold start, portrait/landscape, Fire tablet large text accessibility, privacy policy.
6. Upgrade via later APK signed with the same key IN PLACE; verify preferences still present. Do not uninstall solely to update.
7. Check Cuberoot APK build metadata matches the successful workflow and fingerprint. Never claim device functionality from source alone.

## Status and real device findings
- Unique permanent signing secrets are configured on GitHub and Android signed build 38312727937 PASSED; publisher 38313951860 and Cuberoot Pages deploy 38313972699 PASSED.
- Cuberoot Cloud Files app listing has a description and APK download, but **NO web app Open link**. The public large-print Quick Start Guide is registered under `guides/index.json` at `guides/cloud-files/quick-start.html`.
- **Fire HD 8 acceptance FAIL (reported 2026-10-12):** Cloud Files Upload/Download → Open iCloud Drive shows “Could not open iCloud Drive in Fire browser: No external browser is installed,” despite Fire tablet having Silk.
- Root cause in Android bridge: calling `Intent.resolveActivity(getPackageManager())` before `startActivity`. Modern Android package visibility can return null for available apps when no `<queries>` manifest declaration is present. That is NOT a reliable test of whether Silk can handle the HTTPS link.
- **Fix in `build/android-native.sh`:** remove preflight query, directly dispatch fixed iCloud HTTPS `Intent.ACTION_VIEW` to OS; catch actual `ActivityNotFoundException` if no handler. Do not intercept Apple sign-in in Cloud Files. `build/test-android.cjs` asserts absence of query and presence of direct startActivity + exception handler.
- Pending: new signed build → matching exact Cuberoot publication → install APK over current Cloud Files (same key; never uninstall) → Fire HD 8 test confirming both Upload and Download launch Silk and return to app.

## Fire HD 8 browser launch repair release — 2026-10-12
- Android source fix to remove unreliable `resolveActivity` preflight (Android 11+ package visibility); direct `startActivity(ACTION_VIEW, https://www.icloud.com/iclouddrive/)` with real `ActivityNotFoundException` handling.
- Test correction required after initial test syntax failure; final GitHub Actions Android run `38314654572` PASSED: adapter tests, APK compilation, APK signature verification, upload and report.
- Signed APK sha256 `8061eb092bdd0746c2b6054047e7c0657ee87d28cf5ec1c5736bbeb641f48e6e`; certificate SHA256 `4ac4eb9b55e91582b0b02820498e1f6ee7208a4d63eca73a2c1bf68c766002ea` MATCHES prior released APK.
- Cuberoot publisher run `38314899363` PASS; published build metadata identifies exact APK artifact and matching hashes; GitHub Pages deploy `38314929156` PASS.
- **Fire HD 8 DEVICE ACCEPTANCE — PASS (user-confirmed 2026-10-12):** installed updated Cloud Files APK build `38314654572` successfully over the existing app. Both **Upload → Open iCloud Drive** and **Download → Open iCloud Drive** now launch iCloud Drive in Silk Browser. Earlier incorrect **No external browser is installed** error is resolved. **Not yet tested/confirmed in this session:** actual iCloud file upload/download completion, Local Files picker, persistence of theme preferences, and upgrade of future APKs.
