# templates-gatling — Agent Guide

Gatling performance testing template pack for galaxio CLI (Go template engine, Gatling 3.13.x, Scala 2.13 / Java 21 / Kotlin 2.x). Six templates (scala-sbt, scala-gradle, java-gradle, java-maven, kotlin-gradle, kotlin-maven) — each ships a base simulation set plus optional kafka/jdbc/amqp plugin overlays. Prefer additive changes; template inputs are user-facing API.

CLI repo: https://github.com/galax-io/galaxio-cli (`cmd/galaxio/template.go` — how `init` resolves pack → renders `files/` → merges plugin overlays)

## Commands

```bash
# Local setup: copy shared descriptor to each template dir, register local pack, render a project.
bash .github/scripts/render-descriptors.sh
galaxio template configure --registry "local:$(pwd)"   # once per working copy
galaxio template init "gatling/scala-sbt" --destination ./out \
  --values .github/template-smoke-values.yaml --set KafkaPluginEnabled=true

# Versioning gate: feat→minor, fix→patch. Run before committing.
bash .github/scripts/check-template-version-bump.sh

# Smoke: render template, verify expected files, run Debug simulation vs WireMock (Docker + galaxio on PATH).
bash .github/scripts/run-template-smoke.sh scala-sbt   # any of the 6 template names

# Integration: render scala-sbt with plugin, compile, run Debug simulation vs real services.
# Services: WireMock + Postgres + RabbitMQ + Redpanda (docker-compose.yml in .github/integration/).
docker compose -f .github/integration/docker-compose.yml up -d --wait
bash .github/scripts/run-integration-test.sh kafka   # or: jdbc | amqp
docker compose -f .github/integration/docker-compose.yml down

# Release: v* tag triggers CI (validates tag == galaxio-pack.yaml version → GitHub release).
# One release/X.x branch per major; tags cut from that branch. Never delete a released tag.
# Minor/patch on existing major:
git checkout release/0.x && git cherry-pick <sha>
# bump galaxio-pack.yaml version, then:
git tag v0.15.0 && git push origin release/0.x v0.15.0
# New major:
git checkout -b release/1.x main && git push -u origin release/1.x
git tag v1.0.0 && git push origin v1.0.0
```

## Boundaries

**Always:** bump pack version and all template versions on every change, keep `.github/template-smoke-values.yaml` in sync with new default versions, use semantic commit prefixes (`feat:` → minor, `fix:` → patch).

**Ask first:** new template, new plugin overlay, release workflow changes.

**Never:** force-push or commit to `main`, rename/remove existing inputs, commit broken templates, use versions not on Maven Central in `template-smoke-values.yaml`.
