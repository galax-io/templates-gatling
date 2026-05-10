# templates-gatling

Gatling template pack for `galaxio-cli`.

This repository contains Galaxio project templates for Gatling performance
testing projects.

## Pack

The pack manifest is [`galaxio-pack.yaml`](galaxio-pack.yaml).

```yaml
apiVersion: galaxio.io/v1
kind: TemplatePack
name: gatling
version: 0.6.0
description: Gatling performance testing templates
templates:
  - name: scala-sbt
    version: 0.1.1
    path: scala-sbt
    description: Gatling Scala project with sbt
  - name: java-maven
    version: 0.1.0
    path: java-maven
    description: Gatling Java project with Maven
  - name: kotlin-maven
    version: 0.1.0
    path: kotlin-maven
    description: Gatling Kotlin project with Maven
  - name: scala-gradle
    version: 0.1.0
    path: scala-gradle
    description: Gatling Scala project with Gradle
  - name: java-gradle
    version: 0.1.0
    path: java-gradle
    description: Gatling Java project with Gradle
  - name: kotlin-gradle
    version: 0.1.0
    path: kotlin-gradle
    description: Gatling Kotlin project with Gradle
```

## Templates

| Name | Description |
| --- | --- |
| `scala-sbt` | Gatling Scala project with sbt |
| `java-maven` | Gatling Java project with Maven |
| `kotlin-maven` | Gatling Kotlin project with Maven |
| `scala-gradle` | Gatling Scala project with Gradle |
| `java-gradle` | Gatling Java project with Gradle |
| `kotlin-gradle` | Gatling Kotlin project with Gradle |

## Scala sbt Inputs

`scala-sbt` is a renderable Go-template based project. The template manifest is
[`scala-sbt/galaxio-template.yaml`](scala-sbt/galaxio-template.yaml), and the
project files live under [`scala-sbt/files`](scala-sbt/files).

Useful inputs:

| Input | Default |
| --- | --- |
| `Name` | `myservice` |
| `NameWord` | `myservice` |
| `Package` | `org.galaxio.performance` |
| `PackagePath` | `org/galaxio/performance` |
| `ScalaVersion` | `2.13.18` |
| `GatlingVersion` | `3.11.5` |
| `GatlingPicatinnyVersion` | `1.2.0` |

## Placeholder Syntax

Template files are rendered with Go `text/template` syntax. Values come from the
template manifest defaults, an optional `--values` YAML file, and `--set`
overrides.

Use placeholders as fields on the root data object:

```text
{{ .Name }}
{{ .Package }}
{{ .PackagePath }}
{{ .NameWord }}
```

Placeholders can be used in file contents and file paths:

```text
scala-sbt/files/build.sbt
scala-sbt/files/src/test/scala/{{ .PackagePath }}/{{ .NameWord }}/Debug.scala
```

For example, these values:

```yaml
Name: orders-api
NameWord: ordersapi
Package: org.example.performance
PackagePath: org/example/performance
```

render paths and Scala packages like:

```text
src/test/scala/org/example/performance/ordersapi/Debug.scala
package org.example.performance.ordersapi
```

CLI values override YAML values:

```bash
galaxio template init gatling/scala-sbt \
  --values .github/template-smoke-values.yaml \
  --set Name=orders-api-set \
  --set NameWord=ordersapiset
```

## Developing Templates

Each template lives in its own directory:

```text
scala-sbt/
  galaxio-template.yaml
  files/
    build.sbt
    src/test/scala/{{ .PackagePath }}/{{ .NameWord }}/Debug.scala
```

The pack manifest registers templates in [`galaxio-pack.yaml`](galaxio-pack.yaml).
Renderable templates must define a `path` and contain a `galaxio-template.yaml`.
Placeholder-only templates omit `path` and appear as coming soon in the CLI.

For local development, create a temporary registry that points at this checkout:

```bash
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/registry"
cat > "$tmpdir/registry/galaxio-registry.yaml" <<YAML
apiVersion: galaxio.io/v1
kind: TemplateRegistry
packs:
  - name: gatling
    source: local:$(pwd)
YAML

export GALAXIO_CONFIG="$tmpdir/galaxio-config.yaml"
galaxio template configure --registry "local:$tmpdir/registry"
galaxio template validate local:.
galaxio template init gatling/scala-sbt \
  --destination "$tmpdir/scala-sbt" \
  --values .github/template-smoke-values.yaml
```

After rendering, compile the generated project with its selected language and
build tool:

```bash
cd "$tmpdir/scala-sbt"
sbt -batch Gatling/compile
```

When changing files under a renderable template directory, bump both:
- top-level pack `version`
- `templates[].version` for the changed template

Versioning rule:
- `fix`: patch bump, for example `0.2.0 -> 0.2.1`
- `feat`: minor bump, for example `0.2.0 -> 0.3.0`
- new renderable templates start from `0.1.0`

CI reads the latest commit subject and enforces `fix` vs `feat` bump policy for
pack and changed templates independently.

Run the versioning checker self-test locally with:

```bash
bash .github/scripts/check-template-version-bump_test.sh
```

Release tags drive immutable template consumption. After merging release changes,
create a repository tag such as `v0.1.0`; the release workflow creates GitHub
Release notes. Registries keep pointing at the repository:

```yaml
source: github:galax-io/templates-gatling
```

The CLI uses pack `version` to fetch GitHub tag/release. CLI still shows template
`version` in `template list`.

## Compatibility

`scala-sbt` template targets Picatinny `1.2.0` by default. That release includes
`Utility.banner(injector)` and the current startup diagnostics/config flow used
by the template.

Future extensions that fit the current shape:

- optional protocol modules: Kafka, JDBC, AMQP, JMS
- source-root mode: `src/test/scala` or `src/it/scala`
- workload profile presets: smoke, stability, max performance, closed pacing
- optional NFR assertions from YAML

## Validation

CI installs `galaxio`, validates the pack manifest, configures a local registry,
renders `scala-sbt` through `galaxio template init` with the default Picatinny
version, checks placeholder substitution, and compiles the rendered Scala+sbt
project with `sbt -batch Gatling/compile`.
