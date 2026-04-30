# templates-gatling

Gatling template pack for `galaxio-cli`.

This repository defines the pack and template metadata first. Template files
will be added separately.

## Pack

The pack manifest is [`galaxio-pack.yaml`](galaxio-pack.yaml).

```yaml
apiVersion: galaxio.io/v1
kind: TemplatePack
name: gatling
version: 0.2.0
description: Gatling performance testing templates
templates:
  - name: scala-sbt
    version: 0.2.0
    path: scala-sbt
    description: Gatling Scala project with sbt
  - name: java-maven
    description: Gatling Java project with Maven
  - name: kotlin-maven
    description: Gatling Kotlin project with Maven
  - name: scala-gradle
    description: Gatling Scala project with Gradle
  - name: java-gradle
    description: Gatling Java project with Gradle
  - name: kotlin-gradle
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
| `Organization` | `org.galaxio` |
| `Package` | `org.galaxio.performance` |
| `PackagePath` | `org/galaxio/performance` |
| `BaseUrl` | `https://example.com` |
| `ScalaVersion` | `2.13.18` |
| `GatlingVersion` | `3.11.5` |

Future extensions that fit the current shape:

- optional protocol modules: Kafka, JDBC, AMQP, JMS
- source-root mode: `src/test/scala` or `src/it/scala`
- workload profile presets: smoke, stability, max performance, closed pacing
- optional NFR assertions from YAML

## Validation

CI installs the latest `galaxio` CLI, validates the pack manifest, configures a
local registry, renders `scala-sbt` through `galaxio template init`, and checks
the rendered project structure and placeholder substitution.
