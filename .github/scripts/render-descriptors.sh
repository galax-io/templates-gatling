#!/usr/bin/env bash
# Copy the single source-of-truth descriptor (_common/galaxio-template.yaml)
# into every template directory. Per-template copies are gitignored and only
# materialized for local galaxio usage and CI.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
src="${repo_root}/_common/galaxio-template.yaml"

for t in scala-sbt scala-gradle java-gradle java-maven kotlin-gradle kotlin-maven; do
  cp "${src}" "${repo_root}/${t}/galaxio-template.yaml"
done
