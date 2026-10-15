# Cloud Files — web baseline and Android branch map

**Documentation snapshot: 2026-10-15.** The small original web baseline remains on `cloud-files/main`. The **native Amazon Fire HD 8 application** and permanent APK signing/publishing workflow are isolated to `cloud-files/android`. Do not merge native Java/Capacitor code into this web branch or rebuild the app merely for documentation.

Cloud Files is a portal that opens Apple's iCloud Drive in an **external** browser and provides access to the Android file picker; it does not host, upload, cache or synchronize the user's iCloud credentials/files. Cuberoot holds the public landing/download page. The owner-accepted Android browser-launch correction and remaining device tests are recorded in `android/ANDROID-PLAN.md`. The owner's build/development freeze remains in force; documentation and non-development audit may continue.
