#!/usr/bin/env bash

set -euo pipefail

if (($# != 2)); then
  echo "Usage: verify-android-emulator.sh <artifact-directory> <package-id>" >&2
  exit 2
fi

artifact_directory=$1
package_id=$2
[[ -d "$artifact_directory" ]] || {
  echo "Android artifact directory does not exist: $artifact_directory" >&2
  exit 1
}
[[ "$package_id" =~ ^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$ ]] || {
  echo "Invalid Android package ID: $package_id" >&2
  exit 1
}
command -v adb >/dev/null 2>&1 || {
  echo "adb is required" >&2
  exit 1
}

mapfile -t apks < <(find "$artifact_directory" -type f -name '*-signed.apk' -print)
if ((${#apks[@]} != 1)); then
  printf 'Expected one signed APK, found %d.\n' "${#apks[@]}" >&2
  exit 1
fi

adb logcat -c
adb install --replace "${apks[0]}"
launch_output="$(adb shell am start -W -n "$package_id/.MainActivity")"
printf '%s\n' "$launch_output"
grep -Fq 'Status: ok' <<<"$launch_output"
test -n "$(adb shell pidof "$package_id")"
sleep 10
test -n "$(adb shell pidof "$package_id")"

crash_output="$(adb logcat -b crash -d)"
if grep -Fq "$package_id" <<<"$crash_output"; then
  printf '%s\n' "$crash_output" >&2
  exit 1
fi
