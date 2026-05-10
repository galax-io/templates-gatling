#!/usr/bin/env bash
set -euo pipefail

base_ref="${GITHUB_BASE_REF:-main}"
base="origin/${base_ref}"

git fetch origin "${base_ref}" --depth=1

change_subject="$(git log -1 --pretty=%s)"
change_kind="other"
case "${change_subject}" in
  feat:*|feat\(*)
    change_kind="feat"
    ;;
  fix:*|fix\(*)
    change_kind="fix"
    ;;
esac

pack_version_for() {
  awk '$1 == "version:" { print $2; exit }' "$1"
}

semver_parts() {
  local version="$1"
  local major minor patch
  IFS=. read -r major minor patch <<< "${version}"
  echo "${major:-0} ${minor:-0} ${patch:-0}"
}

is_patch_bump() {
  local old="$1"
  local new="$2"
  local old_major old_minor old_patch new_major new_minor new_patch
  read -r old_major old_minor old_patch <<< "$(semver_parts "${old}")"
  read -r new_major new_minor new_patch <<< "$(semver_parts "${new}")"
  [[ "${new_major}" == "${old_major}" && "${new_minor}" == "${old_minor}" && "${new_patch}" -gt "${old_patch}" ]]
}

is_minor_bump() {
  local old="$1"
  local new="$2"
  local old_major old_minor old_patch new_major new_minor new_patch
  read -r old_major old_minor old_patch <<< "$(semver_parts "${old}")"
  read -r new_major new_minor new_patch <<< "$(semver_parts "${new}")"
  [[ "${new_major}" == "${old_major}" && "${new_minor}" -gt "${old_minor}" ]]
}

ensure_policy_bump() {
  local label="$1"
  local old="$2"
  local new="$3"

  if [[ "${change_kind}" == "feat" ]]; then
    if ! is_minor_bump "${old}" "${new}"; then
      echo "${label} must use a minor bump for feat changes: ${old} -> ${new}" >&2
      exit 1
    fi
    return
  fi

  if [[ "${change_kind}" == "fix" ]]; then
    if ! is_patch_bump "${old}" "${new}"; then
      echo "${label} must use a patch bump for fix changes: ${old} -> ${new}" >&2
      exit 1
    fi
    return
  fi

  if [[ "${old}" == "${new}" ]]; then
    echo "${label} stayed ${new}; bump it and use a feat/fix commit prefix." >&2
    exit 1
  fi
}

template_version_for() {
  local template_name="$1"
  local manifest="$2"
  awk '
    $1 == "-" && $2 == "name:" && $3 == template_name { in_template = 1; next }
    in_template && $1 == "-" && $2 == "name:" { exit }
    in_template && $1 == "version:" { print $2; exit }
  ' template_name="$template_name" "$manifest"
}

old_manifest="$(mktemp)"
git show "${base}:galaxio-pack.yaml" > "${old_manifest}"

old_pack_version="$(pack_version_for "${old_manifest}")"
new_pack_version="$(pack_version_for galaxio-pack.yaml)"

templates=(scala-sbt scala-gradle java-maven kotlin-maven)
changed_any=0

for template in "${templates[@]}"; do
  changed_files="$(git diff --name-only "${base}"...HEAD -- "${template}" || true)"
  if [[ -z "${changed_files}" ]]; then
    continue
  fi

  changed_any=1
  old_template_version="$(template_version_for "${template}" "${old_manifest}")"
  new_template_version="$(template_version_for "${template}" galaxio-pack.yaml)"

  if [[ -z "${new_pack_version}" ]]; then
    echo "${template} changed, but galaxio-pack.yaml does not define pack version" >&2
    exit 1
  fi

  if [[ "${old_pack_version}" == "${new_pack_version}" ]]; then
    echo "${template} changed, but pack version stayed ${new_pack_version}" >&2
    echo "Bump top-level pack version in galaxio-pack.yaml." >&2
    exit 1
  fi

  ensure_policy_bump "pack version" "${old_pack_version}" "${new_pack_version}"

  if [[ -z "${new_template_version}" ]]; then
    echo "${template} changed, but templates[].version for ${template} is missing" >&2
    exit 1
  fi

  if [[ -z "${old_template_version}" ]]; then
    if [[ "${new_template_version}" != "0.1.0" ]]; then
      echo "${template} is newly renderable; start its template version at 0.1.0" >&2
      exit 1
    fi
    continue
  fi

  if [[ "${old_template_version}" == "${new_template_version}" ]]; then
    echo "${template} changed, but ${template} template version stayed ${new_template_version}" >&2
    echo "Bump templates[].version for ${template} in galaxio-pack.yaml." >&2
    exit 1
  fi

  ensure_policy_bump "${template} template version" "${old_template_version}" "${new_template_version}"
done

if [[ "${changed_any}" -eq 0 ]]; then
  exit 0
fi
