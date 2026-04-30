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
  awk '
    $1 == "-" && $2 == "name:" && $3 == "scala-sbt" { in_template = 1; next }
    in_template && $1 == "-" && $2 == "name:" { exit }
    in_template && $1 == "version:" { print $2; exit }
  ' "$1"
}

old_manifest="$(mktemp)"
git show "${base}:galaxio-pack.yaml" > "${old_manifest}"

old_version="$(version_for "${old_manifest}")"
new_version="$(version_for galaxio-pack.yaml)"

if [[ -z "${new_version}" ]]; then
  echo "scala-sbt changed, but galaxio-pack.yaml does not define a scala-sbt version" >&2
  exit 1
fi

if [[ "${old_version}" == "${new_version}" ]]; then
  echo "scala-sbt changed, but its version stayed ${new_version}" >&2
  echo "Bump templates[].version for scala-sbt in galaxio-pack.yaml." >&2
  exit 1
fi
