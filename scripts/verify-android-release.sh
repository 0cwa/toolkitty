#!/usr/bin/env bash

set -euo pipefail

readonly EXPECTED_ABIS=(arm64-v8a armeabi-v7a x86_64)
readonly EXPECTED_NATIVE_LIBRARY=libtoolkitty_lib.so

usage() {
  cat >&2 <<'EOF'
Usage: verify-android-release.sh <apk> <aab> <expected-package> <expected-version-name> <expected-version-code> <expected-cert-sha256>
EOF
}

die() {
  printf 'Android release verification failed: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

normalize_fingerprint() {
  printf '%s' "$1" |
    tr -d '[:space:]:' |
    tr '[:lower:]' '[:upper:]'
}

normalize_output() {
  printf '%s' "$1" | tr -d '\r\n'
}

resolve_build_tools_dir() {
  local requested_version=${ANDROID_BUILD_TOOLS_VERSION:-}
  local build_tools_root="$android_sdk_root/build-tools"
  local -a versions=()

  [[ -d "$build_tools_root" ]] || die "Android SDK has no build-tools directory"
  if [[ -n "$requested_version" ]]; then
    [[ -d "$build_tools_root/$requested_version" ]] ||
      die "requested Android Build Tools version is not installed"
    printf '%s\n' "$build_tools_root/$requested_version"
    return
  fi

  mapfile -t versions < <(
    find "$build_tools_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' |
      LC_ALL=C sort -V
  )
  ((${#versions[@]} > 0)) || die "no Android Build Tools version is installed"
  printf '%s\n' "$build_tools_root/${versions[-1]}"
}

resolve_apkanalyzer() {
  local candidate
  local -a candidates=()

  if command -v apkanalyzer >/dev/null 2>&1; then
    command -v apkanalyzer
    return
  fi

  candidate="$android_sdk_root/cmdline-tools/latest/bin/apkanalyzer"
  if [[ -x "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return
  fi

  mapfile -t candidates < <(
    find "$android_sdk_root/cmdline-tools" -mindepth 3 -maxdepth 3 \
      -type f -path '*/bin/apkanalyzer' -perm -u+x -print 2>/dev/null |
      LC_ALL=C sort -V
  )
  ((${#candidates[@]} > 0)) || die "apkanalyzer was not found in the Android SDK"
  printf '%s\n' "${candidates[-1]}"
}

resolve_llvm_objdump() {
  local -a candidates=()

  mapfile -t candidates < <(
    find "$android_ndk_root/toolchains/llvm/prebuilt" -mindepth 3 -maxdepth 3 \
      -type f -path '*/bin/llvm-objdump' -perm -u+x -print 2>/dev/null
  )
  ((${#candidates[@]} == 1)) ||
    die "expected exactly one llvm-objdump in the configured Android NDK"
  printf '%s\n' "${candidates[0]}"
}

archive_members() {
  unzip -Z1 "$1"
}

verify_exact_abis() {
  local archive=$1
  local archive_kind=$2
  local prefix pattern expected_fields abi
  local actual_file="$temporary_dir/$archive_kind-actual-abis"
  local expected_file="$temporary_dir/$archive_kind-expected-abis"
  local reference_libraries=

  if [[ "$archive_kind" == apk ]]; then
    prefix=lib
    expected_fields=3
  else
    prefix=base/lib
    expected_fields=4
  fi
  pattern="^${prefix}/[^/]+/[^/]+[.]so$"

  archive_members "$archive" |
    awk -F/ -v pattern="$pattern" '$0 ~ pattern { print $(NF - 1) }' |
    LC_ALL=C sort -u >"$actual_file"
  printf '%s\n' "${EXPECTED_ABIS[@]}" >"$expected_file"
  if ! diff -u "$expected_file" "$actual_file"; then
    die "$archive_kind does not contain the exact required ABI set"
  fi

  for abi in "${EXPECTED_ABIS[@]}"; do
    local libraries_file="$temporary_dir/$archive_kind-$abi-libraries"
    archive_members "$archive" |
      awk -F/ -v root="$prefix/$abi/" -v fields="$expected_fields" '
        index($0, root) == 1 && NF == fields && $NF ~ /[.]so$/ { print $NF }
      ' |
      LC_ALL=C sort -u >"$libraries_file"
    grep -Fxq "$EXPECTED_NATIVE_LIBRARY" "$libraries_file" ||
      die "$archive_kind is missing $EXPECTED_NATIVE_LIBRARY for $abi"
    if [[ -z "$reference_libraries" ]]; then
      reference_libraries=$libraries_file
    elif ! diff -u "$reference_libraries" "$libraries_file"; then
      die "$archive_kind native-library sets differ between ABIs"
    fi
  done
}

verify_elf_alignment() {
  local archive=$1
  local archive_kind=$2
  local prefix member extracted
  local index=0
  local -a members=()

  if [[ "$archive_kind" == apk ]]; then
    prefix=lib
  else
    prefix=base/lib
  fi

  mapfile -t members < <(
    archive_members "$archive" |
      awk -v prefix="$prefix" '
        $0 ~ ("^" prefix "/(arm64-v8a|x86_64)/[^/]+[.]so$") { print }
      '
  )
  ((${#members[@]} > 0)) || die "$archive_kind has no 64-bit native libraries"

  for member in "${members[@]}"; do
    index=$((index + 1))
    extracted="$temporary_dir/$archive_kind-elf-$index.so"
    unzip -p "$archive" "$member" >"$extracted" ||
      die "could not extract a native library from $archive_kind"
    if ! "$llvm_objdump" -p "$extracted" | awk '
      $1 == "LOAD" {
        seen = 1
        if (split($NF, alignment, "[*][*]") != 2 || alignment[2] + 0 < 14) {
          bad = 1
        }
      }
      END { exit !(seen && !bad) }
    '; then
      die "$archive_kind contains a 64-bit ELF LOAD segment below 16 KiB alignment"
    fi
  done
}

verify_apk_signature() {
  local signature_output="$temporary_dir/apk-signature.txt"
  local -a fingerprints=()

  if ! "$apksigner" verify --verbose --print-certs "$apk_path" \
    >"$signature_output" 2>&1; then
    die "APK signature verification failed"
  fi
  mapfile -t fingerprints < <(
    awk -F': ' '/certificate SHA-256 digest:/ { print $2 }' "$signature_output" |
      while IFS= read -r fingerprint; do
        normalize_fingerprint "$fingerprint"
        printf '\n'
      done |
      LC_ALL=C sort -u
  )
  ((${#fingerprints[@]} == 1)) || die "APK does not have exactly one signing certificate"
  [[ "${fingerprints[0]}" == "$expected_cert_sha256" ]] ||
    die "APK signing certificate fingerprint does not match"
}

verify_aab_signature() {
  local signature_output="$temporary_dir/aab-signature.txt"
  local certificate_output="$temporary_dir/aab-certificate.txt"
  local -a fingerprints=()
  local jarsigner_status

  set +e
  LC_ALL=C jarsigner -verify -strict -verbose -certs "$aab_path" \
    >"$signature_output" 2>&1
  jarsigner_status=$?
  set -e

  # JDKs reuse strict-warning bits. Reject every structural, algorithm, and
  # certificate-usage bit; code 4 is allowed only for the expected self-signed
  # distribution certificate/chain warning and is inspected textually below.
  if ((jarsigner_status & 1 || jarsigner_status & 8 || jarsigner_status & 16 ||
    jarsigner_status & 32 || jarsigner_status & 64)); then
    die "AAB signature verification reported a disallowed signer error"
  fi
  if grep -Eqi \
    'unsigned entries|treated as unsigned|algorithm.*disabled|disabled algorithm|certificate.*expired|not yet valid|KeyUsage extension|ExtendedKeyUsage|NetscapeCertType|timestamp.*(expired|invalid)' \
    "$signature_output"; then
    die "AAB signature verification reported an integrity or certificate error"
  fi
  if ((jarsigner_status != 0)); then
    ((jarsigner_status == 4)) || die "AAB signature verification failed"
    grep -Eqi 'self[- ]signed' "$signature_output" ||
      die "AAB signature verification reported an unexpected certificate-chain error"
  fi
  grep -Eq '^jar verified(, with signer errors)?[.]$' "$signature_output" ||
    die "AAB is not a verified signed JAR"
  LC_ALL=C keytool -printcert -jarfile "$aab_path" >"$certificate_output" 2>&1 ||
    die "could not read the AAB signing certificate"
  mapfile -t fingerprints < <(
    awk -F': ' '/SHA256:/ { print $2 }' "$certificate_output" |
      while IFS= read -r fingerprint; do
        normalize_fingerprint "$fingerprint"
        printf '\n'
      done |
      LC_ALL=C sort -u
  )
  ((${#fingerprints[@]} == 1)) || die "AAB does not have exactly one signing certificate"
  [[ "${fingerprints[0]}" == "$expected_cert_sha256" ]] ||
    die "AAB signing certificate fingerprint does not match"
}

verify_apk_metadata() {
  local actual_package actual_version_name actual_version_code

  actual_package=$(normalize_output "$("$apkanalyzer" manifest application-id "$apk_path")")
  actual_version_name=$(normalize_output "$("$apkanalyzer" manifest version-name "$apk_path")")
  actual_version_code=$(normalize_output "$("$apkanalyzer" manifest version-code "$apk_path")")
  [[ "$actual_package" == "$expected_package" ]] || die "APK package ID does not match"
  [[ "$actual_version_name" == "$expected_version_name" ]] || die "APK version name does not match"
  [[ "$actual_version_code" == "$expected_version_code" ]] || die "APK version code does not match"
}

verify_aab_with_bundletool() {
  local actual_package actual_version_name actual_version_code
  local config_output="$temporary_dir/aab-config.txt"

  [[ -f "$BUNDLETOOL_JAR" && -r "$BUNDLETOOL_JAR" ]] ||
    die "BUNDLETOOL_JAR is not a readable regular file"
  require_command java
  java -jar "$BUNDLETOOL_JAR" validate --bundle="$aab_path"
  actual_package=$(normalize_output "$(
    java -jar "$BUNDLETOOL_JAR" dump manifest --bundle="$aab_path" \
      --module=base --xpath=/manifest/@package
  )")
  actual_version_name=$(normalize_output "$(
    java -jar "$BUNDLETOOL_JAR" dump manifest --bundle="$aab_path" \
      --module=base --xpath=/manifest/@android:versionName
  )")
  actual_version_code=$(normalize_output "$(
    java -jar "$BUNDLETOOL_JAR" dump manifest --bundle="$aab_path" \
      --module=base --xpath=/manifest/@android:versionCode
  )")
  [[ "$actual_package" == "$expected_package" ]] || die "AAB package ID does not match"
  [[ "$actual_version_name" == "$expected_version_name" ]] || die "AAB version name does not match"
  [[ "$actual_version_code" == "$expected_version_code" ]] || die "AAB version code does not match"
  java -jar "$BUNDLETOOL_JAR" dump config --bundle="$aab_path" >"$config_output"
  grep -q 'PAGE_ALIGNMENT_16K' "$config_output" ||
    die "AAB does not request 16 KiB native-library page alignment"
}

if (($# != 6)); then
  usage
  exit 2
fi

apk_path=$1
aab_path=$2
expected_package=$3
expected_version_name=$4
expected_version_code=$5
expected_cert_sha256=$(normalize_fingerprint "$6")

[[ -f "$apk_path" && -r "$apk_path" ]] || die "APK is not a readable regular file"
[[ -f "$aab_path" && -r "$aab_path" ]] || die "AAB is not a readable regular file"
for command_name in awk diff find grep jarsigner keytool mktemp realpath sort tr unzip; do
  require_command "$command_name"
done
apk_path=$(realpath -- "$apk_path")
aab_path=$(realpath -- "$aab_path")
[[ "$apk_path" != "$aab_path" ]] || die "APK and AAB paths must be different"
[[ "$expected_package" =~ ^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$ ]] ||
  die "expected package ID is invalid"
[[ -n "$expected_version_name" &&
  "$expected_version_name" != *$'\n'* &&
  "$expected_version_name" != *$'\r'* ]] ||
  die "expected version name is invalid"
[[ "$expected_version_code" =~ ^[0-9]+$ ]] || die "expected version code is invalid"
[[ "$expected_cert_sha256" =~ ^[0-9A-F]{64}$ ]] ||
  die "expected certificate SHA-256 fingerprint is invalid"

android_sdk_root=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
android_ndk_root=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-${ANDROID_NDK:-${NDK_HOME:-}}}}
[[ -n "$android_sdk_root" && -d "$android_sdk_root" ]] ||
  die "ANDROID_HOME or ANDROID_SDK_ROOT must name an Android SDK directory"
[[ -n "$android_ndk_root" && -d "$android_ndk_root" ]] ||
  die "an Android NDK environment variable must name an NDK directory"
android_sdk_root=$(realpath -- "$android_sdk_root")
android_ndk_root=$(realpath -- "$android_ndk_root")
[[ -n ${BUNDLETOOL_JAR:-} ]] || die "BUNDLETOOL_JAR must be set"
[[ -f "$BUNDLETOOL_JAR" && -r "$BUNDLETOOL_JAR" ]] ||
  die "BUNDLETOOL_JAR is not a readable regular file"
require_command java
BUNDLETOOL_JAR=$(realpath -- "$BUNDLETOOL_JAR")

temporary_dir=$(mktemp -d)
trap 'rm -rf -- "$temporary_dir"' EXIT
build_tools_dir=$(resolve_build_tools_dir)
apksigner="$build_tools_dir/apksigner"
zipalign="$build_tools_dir/zipalign"
[[ -x "$apksigner" ]] || die "apksigner was not found in Android Build Tools"
[[ -x "$zipalign" ]] || die "zipalign was not found in Android Build Tools"
apkanalyzer=$(resolve_apkanalyzer)
llvm_objdump=$(resolve_llvm_objdump)

verify_apk_signature
verify_aab_signature
verify_apk_metadata
verify_exact_abis "$apk_path" apk
verify_exact_abis "$aab_path" aab
"$zipalign" -c -P 16 -v 4 "$apk_path" >/dev/null || die "APK is not 16 KiB zip-aligned"
verify_elf_alignment "$apk_path" apk
verify_elf_alignment "$aab_path" aab

verify_aab_with_bundletool

printf 'Android release verification successful.\n'
