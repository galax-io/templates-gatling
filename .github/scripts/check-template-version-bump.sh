#!/usr/bin/env bash
set -euo pipefail

base_ref="${GITHUB_BASE_REF:-main}"
base="origin/${base_ref}"

git fetch origin "${base_ref}" --depth=1

changed_files="$(git diff --name-only "${base}"...HEAD -- scala-sbt || true)"
if [[ -z "${changed_files}" ]]; then
  exit 0
fi

pack_version_for() {
  awk '$1 == "version:" { print $2; exit }' "$1"
}

template_version_for() {
  awk '
    $1 == "-" && $2 == "name:" && $3 == "scala-sbt" { in_template = 1; next }
    in_template && $1 == "-" && $2 == "name:" { exit }
    in_template && $1 == "version:" { print $2; exit }
  ' "$1"
}

old_manifest="$(mktemp)"
git show "${base}:galaxio-pack.yaml" > "${old_manifest}"

old_pack_version="$(pack_version_for "${old_manifest}")"
new_pack_version="$(pack_version_for galaxio-pack.yaml)"
old_template_version="$(template_version_for "${old_manifest}")"
new_template_version="$(template_version_for galaxio-pack.yaml)"

if [[ -z "${new_pack_version}" ]]; then
  echo "scala-sbt changed, but galaxio-pack.yaml does not define pack version" >&2
  exit 1
fi

if [[ "${old_pack_version}" == "${new_pack_version}" ]]; then
  echo "scala-sbt changed, but pack version stayed ${new_pack_version}" >&2
  echo "Bump top-level pack version in galaxio-pack.yaml." >&2
  exit 1
fi

if [[ -z "${new_template_version}" ]]; then
  echo "scala-sbt changed, but templates[].version for scala-sbt is missing" >&2
  exit 1
fi

if [[ "${old_template_version}" == "${new_template_version}" ]]; then
  echo "scala-sbt changed, but scala-sbt template version stayed ${new_template_version}" >&2
  echo "Bump templates[].version for scala-sbt in galaxio-pack.yaml." >&2
  exit 1
fi
