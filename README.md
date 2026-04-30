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
