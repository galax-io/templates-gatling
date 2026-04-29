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
version: 0.1.0
description: Gatling performance testing templates
templates:
  - name: scala-sbt
    description: Gatling Scala project with sbt
```

## Templates

| Name | Description |
| --- | --- |
| `scala-sbt` | Gatling Scala project with sbt |
