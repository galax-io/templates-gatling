#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
tmp="$(mktemp -d)"

run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 8m "$@"
    return
  fi
  "$@"
}

git clone --depth 1 https://github.com/galax-io/gatling-template.g8 "${tmp}/gatling-template.g8"

mkdir -p "${tmp}/g8-render"
(
  cd "${tmp}/g8-render"
  run_with_timeout sbt -batch new "file://${tmp}/gatling-template.g8" \
    --name=orders-api \
    --package=org.example.performance \
    --http=true \
    --jdbcPlugin=false \
    --amqpPlugin=false \
    --kafkaPlugin=false \
    --scala_version=2.13.18 \
    --gatling_version=3.11.5 \
    --sbt_version=1.12.2 \
    --sbt_gatling_version=4.18.0 \
    --sbt_scalafmt_version=2.5.6 \
    --gatling_picatinny_version=1.0.1 \
    --force
)

mkdir -p "${tmp}/registry"
cat > "${tmp}/registry/galaxio-registry.yaml" <<YAML
apiVersion: galaxio.io/v1
kind: TemplateRegistry
packs:
  - name: gatling
    source: local:${root}
YAML

export GALAXIO_CONFIG="${tmp}/galaxio-config.yaml"
galaxio template configure --registry "local:${tmp}/registry" >/dev/null
galaxio template init gatling/scala-sbt \
  --destination "${tmp}/galaxio-render" \
  --values "${root}/.github/template-smoke-values.yaml" >/dev/null

diff -ru "${tmp}/g8-render/orders-api" "${tmp}/galaxio-render"
