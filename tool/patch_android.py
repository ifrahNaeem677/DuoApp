"""Run by the GitHub build after `flutter create`.

Adds what DuoDeen V2 needs on Android:
  * core library desugaring (required by flutter_local_notifications)
  * Java 11+ compile options
  * INTERNET permission (release apps need it to reach Supabase)
  * notification permissions + receivers
  * app name "DuoDeen"
The Kotlin jvmTarget and compileSdk/minSdk from Flutter's own template are kept
(flutter_local_notifications 19 needs compileSdk 35+, which Flutter's default provides).
"""
import pathlib
import re
import sys

app = pathlib.Path("android/app")

# ---------------------------------------------------------------- Gradle
kts = app / "build.gradle.kts"
groovy = app / "build.gradle"

if kts.exists():
    path, g, kotlin_dsl = kts, kts.read_text(encoding="utf-8"), True
elif groovy.exists():
    path, g, kotlin_dsl = groovy, groovy.read_text(encoding="utf-8"), False
else:
    sys.exit("ERROR: android/app/build.gradle(.kts) not found. Did `flutter create` run?")

enable_line = "isCoreLibraryDesugaringEnabled = true" if kotlin_dsl else "coreLibraryDesugaringEnabled true"
dep_line = (
    'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
    if kotlin_dsl
    else "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'"
)

# 1) compileOptions with desugaring
if "oreLibraryDesugaringEnabled" not in g:
    if re.search(r"compileOptions\s*\{", g):
        g = re.sub(r"compileOptions\s*\{", lambda m: m.group(0) + "\n        " + enable_line, g, count=1)
    else:
        block = (
            "\n    compileOptions {\n"
            f"        {enable_line}\n"
            + ("        sourceCompatibility = JavaVersion.VERSION_11\n        targetCompatibility = JavaVersion.VERSION_11\n"
               if kotlin_dsl else
               "        sourceCompatibility JavaVersion.VERSION_11\n        targetCompatibility JavaVersion.VERSION_11\n")
            + "    }\n"
        )
        g, n = re.subn(r"android\s*\{", lambda m: m.group(0) + block, g, count=1)
        if n == 0:
            sys.exit("ERROR: android { } block not found in " + str(path))

# 2) Java version must be at least 11 (template may say 1.8 on old Flutter)
g = g.replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_11")

# 3) desugar library dependency
if "desugar_jdk_libs" not in g:
    g = g.rstrip() + "\n\ndependencies {\n    " + dep_line + "\n}\n"

path.write_text(g, encoding="utf-8")
print("Patched", path)

# ---------------------------------------------------------------- Manifest
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

# ---------------------------------------------------------------- Verify
final = path.read_text(encoding="utf-8")
assert "oreLibraryDesugaringEnabled" in final and "desugar_jdk_libs" in final, "desugaring patch failed"
assert "android.permission.INTERNET" in manifest.read_text(encoding="utf-8"), "INTERNET patch failed"
print("\n----- " + str(path) + " -----\n" + final)
print("All Android patches OK ✅")
