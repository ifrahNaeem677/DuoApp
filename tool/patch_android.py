"""Run by the GitHub build after `flutter create`.

Adds what DuoDeen V2 needs on Android:
  * INTERNET permission (release apps need it to reach Supabase)
  * notification permissions + receivers (flutter_local_notifications)
  * core library desugaring (required by flutter_local_notifications)
  * app name "DuoDeen"
"""
import pathlib
import re
import sys

app = pathlib.Path("android/app")

# ---------- AndroidManifest.xml ----------
manifest = app / "src/main/AndroidManifest.xml"
x = manifest.read_text(encoding="utf-8")

perms = [
    "android.permission.INTERNET",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
]
missing = [p for p in perms if p not in x]
if missing:
    lines = "".join(f'\n    <uses-permission android:name="{p}"/>' for p in missing)
    x = re.sub(r"(<manifest[^>]*>)", lambda m: m.group(1) + lines, x, count=1)

receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
if "ScheduledNotificationReceiver" not in x:
    x = x.replace("</application>", receivers + "    </application>", 1)

x = re.sub(r'android:label="[^"]*"', 'android:label="DuoDeen"', x, count=1)
manifest.write_text(x, encoding="utf-8")
print("Patched", manifest)

# ---------- Gradle: core library desugaring ----------
kts = app / "build.gradle.kts"
groovy = app / "build.gradle"
if kts.exists():
    g = kts.read_text(encoding="utf-8")
    if "isCoreLibraryDesugaringEnabled" not in g:
        if "compileOptions {" not in g:
            sys.exit("compileOptions block not found in build.gradle.kts")
        g = g.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
    if "desugar_jdk_libs" not in g:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    kts.write_text(g, encoding="utf-8")
    print("Patched", kts)
elif groovy.exists():
    g = groovy.read_text(encoding="utf-8")
    if "coreLibraryDesugaringEnabled" not in g:
        if "compileOptions {" not in g:
            sys.exit("compileOptions block not found in build.gradle")
        g = g.replace("compileOptions {", "compileOptions {\n        coreLibraryDesugaringEnabled true", 1)
    if "desugar_jdk_libs" not in g:
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    groovy.write_text(g, encoding="utf-8")
    print("Patched", groovy)
else:
    sys.exit("No android/app/build.gradle(.kts) found")
