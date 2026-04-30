# {{ .Name }}

{{ .Description }}

## Run

```bash
sbt Gatling/compile
sbt 'Gatling/testOnly {{ .Package }}.DebugSimulation'
sbt 'Gatling/testOnly {{ .Package }}.StabilitySimulation'
sbt 'Gatling/testOnly {{ .Package }}.MaxPerformanceSimulation'
```

Runtime settings live in `src/test/resources/simulation.conf` and can be
overridden with JVM properties:

```bash
sbt 'Gatling/testOnly {{ .Package }}.DebugSimulation' -DbaseUrl=https://example.com
```
