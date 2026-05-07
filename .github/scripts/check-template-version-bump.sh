#!/usr/bin/env bash
set -euo pipefail

base_ref="${GITHUB_BASE_REF:-main}"
base="origin/${base_ref}"

git fetch origin "${base_ref}" --depth=1

changed_files="$(git diff --name-only "${base}"...HEAD -- scala-sbt || true)"
if [[ -z "${changed_files}" ]]; then
  exit 0
fi

version_for() {
  awk '$1 == "version:" { print $2; exit }' "$1"
}

old_manifest="$(mktemp)"
git show "${base}:galaxio-pack.yaml" > "${old_manifest}"

old_version="$(version_for "${old_manifest}")"
new_version="$(version_for galaxio-pack.yaml)"

if [[ -z "${new_version}" ]]; then
  echo "scala-sbt changed, but galaxio-pack.yaml does not define pack version" >&2
  exit 1
fi

if [[ "${old_version}" == "${new_version}" ]]; then
  echo "scala-sbt changed, but pack version stayed ${new_version}" >&2
  echo "Bump top-level pack version in galaxio-pack.yaml." >&2
  exit 1
fi
