#!/usr/bin/env bash
# Generate Android-only native bridge in the ephemeral Capacitor project.
set -euo pipefail
DIR="android/app/src/main/java/io/github/willyros01/cloudfiles"
mkdir -p "$DIR"
cat > "$DIR/MainActivity.java" <<'JAVA'
package io.github.willyros01.cloudfiles;
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;
public class MainActivity extends BridgeActivity {
  @Override public void onCreate(Bundle savedInstanceState) {
    registerPlugin(CloudFilesLinksPlugin.class);
    super.onCreate(savedInstanceState);
  }
}
JAVA
cat > "$DIR/CloudFilesLinksPlugin.java" <<'JAVA'
package io.github.willyros01.cloudfiles;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
@CapacitorPlugin(name = "CloudFilesLinks")
public class CloudFilesLinksPlugin extends Plugin {
  @PluginMethod
  public void openICloud(PluginCall call) {
    // Always use the OS browser (normally Silk on Amazon Fire).
    // iCloud credentials never enter this application's WebView.
    try {
      Intent browser = new Intent(Intent.ACTION_VIEW, Uri.parse("https://www.icloud.com/iclouddrive/"));
      browser.addCategory(Intent.CATEGORY_BROWSABLE);
      browser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      // Android 11+ package visibility can make resolveActivity() return null
      // even when Amazon Silk is installed and can handle this HTTPS intent.
      // Launch directly: Android itself resolves the activity, and only a real
      // ActivityNotFoundException means there is no browser handler.
      getContext().startActivity(browser);
      call.resolve(new JSObject());
    } catch (ActivityNotFoundException e) {
      call.reject("No external browser is available", e);
    } catch (Exception e) {
      call.reject("Unable to open iCloud Drive", e);
    }
  }
}
JAVA
