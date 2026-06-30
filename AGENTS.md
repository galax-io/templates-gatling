# templates-gatling — Agent Guide

Gatling performance testing template pack for galaxio CLI (Go template engine, Gatling 3.13.x, Scala 2.13 / Java 17 / Kotlin 2.x). Six templates (scala-sbt, scala-gradle, java-gradle, java-maven, kotlin-gradle, kotlin-maven) — each ships a base simulation set plus optional kafka/jdbc/amqp plugin overlays. Prefer additive changes; template inputs are user-facing API.

CLI repo: https://github.com/galax-io/galaxio-cli (`cmd/galaxio/template.go` — how `init` resolves pack → renders `files/` → merges plugin overlays)

## Commands

```bash
# Local setup: register local pack (once per working copy), render a project.
galaxio template configure --registry "local:$(pwd)"
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

# Release: v* tag triggers CI — validates tag is on main or release/* branch,
# tag == galaxio-pack.yaml version, then creates GitHub release.
# One release/X.Y branch per minor (e.g. release/0.15). Never delete a released tag.
# Patch on existing minor:
git checkout release/0.15 && git cherry-pick <sha>
# bump galaxio-pack.yaml version, then:
git tag v0.15.1 && git push origin release/0.15 v0.15.1
# New minor/major — cut branch from main, tag:
git checkout -b release/0.16 main && git push -u origin release/0.16
git tag v0.16.0 && git push origin v0.16.0
```

## Boundaries

**Always:** bump pack version and all template versions on every change, keep `.github/template-smoke-values.yaml` in sync with new default versions, use semantic commit prefixes (`feat:` → minor, `fix:` → patch).

**Ask first:** new template, new plugin overlay, release workflow changes.

**Never:** force-push or commit to `main`, rename/remove existing inputs, commit broken templates, use versions not on Maven Central in `template-smoke-values.yaml`.
