#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script_path="${repo_root}/.github/scripts/check-template-version-bump.sh"

failures=0

base_manifest() {
  cat <<'EOF'
apiVersion: galaxio.io/v1
kind: TemplatePack
name: gatling
version: 0.6.0
description: Test templates
templates:
  - name: scala-sbt
    version: 0.1.1
    path: scala-sbt
    description: Scala template
EOF
}

create_repo() {
  local repo_dir="$1"

  git init -b main "$repo_dir" >/dev/null
  git -C "$repo_dir" config user.name "Test User"
  git -C "$repo_dir" config user.email "test@example.com"

  base_manifest > "${repo_dir}/galaxio-pack.yaml"
  mkdir -p "${repo_dir}/scala-sbt/files"
  printf 'base\n' > "${repo_dir}/scala-sbt/files/base.txt"

  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "feat: base pack" >/dev/null
  git -C "$repo_dir" checkout -b feature >/dev/null
}

run_check() {
  local repo_dir="$1"
  shift

  (
    cd "$repo_dir"
    "$@" "${script_path}"
  )
}

assert_success() {
  local name="$1"
  shift

  if "$@"; then
    printf 'PASS %s\n' "$name"
    return
  fi

  printf 'FAIL %s\n' "$name"
  failures=$((failures + 1))
}

assert_failure_contains() {
  local name="$1"
  local expected="$2"
  shift 2

  local output
  if output="$("$@" 2>&1)"; then
    printf 'FAIL %s\nexpected failure containing: %s\n' "$name" "$expected"
    failures=$((failures + 1))
    return
  fi

  if [[ "$output" == *"$expected"* ]]; then
    printf 'PASS %s\n' "$name"
    return
  fi

  printf 'FAIL %s\nexpected output to contain: %s\nactual output:\n%s\n' "$name" "$expected" "$output"
  failures=$((failures + 1))
}

test_fix_change_requires_pack_and_template_bump() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  create_repo "$repo_dir"

  printf 'updated\n' > "${repo_dir}/scala-sbt/files/base.txt"
  perl -0pi -e 's/version: 0\.6\.0/version: 0.6.1/; s/version: 0\.1\.1/version: 0.1.2/' "${repo_dir}/galaxio-pack.yaml"

  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "fix(scala-sbt): adjust template defaults" >/dev/null

  assert_success \
    "fix change with pack+template bump passes" \
    run_check "$repo_dir" env SKIP_FETCH=1 BASE=main
}

test_missing_template_bump_fails() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  create_repo "$repo_dir"

  printf 'updated\n' > "${repo_dir}/scala-sbt/files/base.txt"
  perl -0pi -e 's/version: 0\.6\.0/version: 0.6.1/' "${repo_dir}/galaxio-pack.yaml"

  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "fix(scala-sbt): adjust template defaults" >/dev/null

  assert_failure_contains \
    "missing template bump fails" \
    "scala-sbt changed, but scala-sbt template version stayed 0.1.1" \
    run_check "$repo_dir" env SKIP_FETCH=1 BASE=main
}

test_non_template_change_does_not_require_bump() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  create_repo "$repo_dir"

  printf '# docs\n' > "${repo_dir}/README.md"
  git -C "$repo_dir" add README.md
  git -C "$repo_dir" commit -m "docs: add readme" >/dev/null

  assert_success \
    "non-template change does not require bump" \
    run_check "$repo_dir" env SKIP_FETCH=1 BASE=main
}

test_new_renderable_template_must_start_at_010() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  create_repo "$repo_dir"

  mkdir -p "${repo_dir}/python-poetry/files"
  printf 'service\n' > "${repo_dir}/python-poetry/files/base.txt"
  cat > "${repo_dir}/galaxio-pack.yaml" <<'EOF'
apiVersion: galaxio.io/v1
kind: TemplatePack
name: gatling
version: 0.7.0
description: Test templates
templates:
  - name: scala-sbt
    version: 0.1.1
    path: scala-sbt
    description: Scala template
  - name: python-poetry
    version: 0.2.0
    path: python-poetry
    description: Python template
EOF

  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "feat(python-poetry): add template" >/dev/null

  assert_failure_contains \
    "new renderable template must start at 0.1.0" \
    "python-poetry is newly renderable; start its template version at 0.1.0" \
    run_check "$repo_dir" env SKIP_FETCH=1 BASE=main
}

test_fix_change_requires_pack_bump() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  create_repo "$repo_dir"

  printf 'updated\n' > "${repo_dir}/scala-sbt/files/base.txt"
  perl -0pi -e 's/version: 0\.1\.1/version: 0.1.2/' "${repo_dir}/galaxio-pack.yaml"

  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "fix(scala-sbt): adjust template defaults" >/dev/null

  assert_failure_contains \
    "missing pack bump fails" \
    "scala-sbt changed, but pack version stayed 0.6.0" \
    run_check "$repo_dir" env SKIP_FETCH=1 BASE=main
}

test_fix_change_requires_pack_and_template_bump
test_missing_template_bump_fails
test_non_template_change_does_not_require_bump
test_new_renderable_template_must_start_at_010
test_fix_change_requires_pack_bump

if [[ "$failures" -ne 0 ]]; then
  printf '\n%d test(s) failed\n' "$failures"
  exit 1
fi

printf '\nAll tests passed\n'
