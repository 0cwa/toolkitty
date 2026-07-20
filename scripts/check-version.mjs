#!/usr/bin/env node

import { readFile } from "node:fs/promises";

const cargoManifestPath = new URL("../src-tauri/Cargo.toml", import.meta.url);
const cargoLockPath = new URL("../src-tauri/Cargo.lock", import.meta.url);
const packageManifestPath = new URL("../package.json", import.meta.url);
const packageLockPath = new URL("../package-lock.json", import.meta.url);
const tauriConfigPath = new URL(
  "../src-tauri/tauri.conf.json",
  import.meta.url,
);

function cargoPackageVersion(manifest) {
  const packageHeader = manifest.search(/^\[package\]\s*$/m);
  if (packageHeader === -1) {
    throw new Error("src-tauri/Cargo.toml has no [package] section");
  }

  const packageSectionStart = manifest.indexOf("\n", packageHeader) + 1;
  const remainingManifest = manifest.slice(packageSectionStart);
  const nextSection = remainingManifest.search(/^\[/m);
  const packageSection =
    nextSection === -1
      ? remainingManifest
      : remainingManifest.slice(0, nextSection);
  const version = packageSection.match(/^version\s*=\s*"([^"]+)"\s*$/m)?.[1];

  if (!version) {
    throw new Error("src-tauri/Cargo.toml [package] has no string version");
  }

  return version;
}

function cargoLockPackageVersion(lockfile, packageName) {
  const matchingPackages = lockfile
    .split(/^\[\[package\]\]\s*$/m)
    .slice(1)
    .filter(
      (packageSection) =>
        packageSection.match(/^name\s*=\s*"([^"]+)"\s*$/m)?.[1] === packageName,
    );

  if (matchingPackages.length !== 1) {
    throw new Error(
      `src-tauri/Cargo.lock must contain exactly one ${packageName} package`,
    );
  }

  const version = matchingPackages[0].match(
    /^version\s*=\s*"([^"]+)"\s*$/m,
  )?.[1];

  if (!version) {
    throw new Error(
      `src-tauri/Cargo.lock ${packageName} package has no string version`,
    );
  }

  return version;
}

async function main() {
  const [packageManifest, packageLock, cargoManifest, cargoLock, tauriConfig] =
    await Promise.all([
      readFile(packageManifestPath, "utf8").then(JSON.parse),
      readFile(packageLockPath, "utf8").then(JSON.parse),
      readFile(cargoManifestPath, "utf8"),
      readFile(cargoLockPath, "utf8"),
      readFile(tauriConfigPath, "utf8").then(JSON.parse),
    ]);

  const versions = new Map([
    ["package.json", packageManifest.version],
    ["package-lock.json", packageLock.version],
    ["package-lock.json packages['']", packageLock.packages?.[""]?.version],
    ["src-tauri/Cargo.toml", cargoPackageVersion(cargoManifest)],
    [
      "src-tauri/Cargo.lock toolkitty package",
      cargoLockPackageVersion(cargoLock, "toolkitty"),
    ],
    ["src-tauri/tauri.conf.json", tauriConfig.version],
  ]);

  for (const [file, version] of versions) {
    if (typeof version !== "string" || version.length === 0) {
      throw new Error(`${file} has no valid version string`);
    }
  }

  const distinctVersions = new Set(versions.values());
  if (distinctVersions.size !== 1) {
    const details = [...versions]
      .map(([file, version]) => `${file}=${version}`)
      .join(", ");
    throw new Error(`Version mismatch: ${details}`);
  }

  const [version] = distinctVersions;
  const releaseTag = process.env.RELEASE_TAG || process.argv[2] || "";
  const expectedTag = `v${version}`;
  const androidVersionCode = tauriConfig.bundle?.android?.versionCode;

  if (!Number.isInteger(androidVersionCode) || androidVersionCode <= 0) {
    throw new Error(
      "src-tauri/tauri.conf.json bundle.android.versionCode must be a positive integer",
    );
  }

  if (releaseTag && releaseTag !== expectedTag) {
    throw new Error(
      `Release tag ${releaseTag} does not match manifest version ${expectedTag}`,
    );
  }

  console.log(
    releaseTag
      ? `Version ${version} is consistent and matches ${releaseTag}.`
      : `Version ${version} is consistent across all manifests.`,
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
