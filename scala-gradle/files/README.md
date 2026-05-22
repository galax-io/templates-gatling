# Gatling Template Project

Template project for Gatling performance tests

## Project structure

```
src.gatling.resources - project resources
src.gatling.scala.{{ .Package }}.{{ .NameWord }}.cases - simple cases
src.gatling.scala.{{ .Package }}.{{ .NameWord }}.scenarios - common load scenarios assembled from simple cases
src.gatling.scala.{{ .Package }}.{{ .NameWord }} - common test configs
```

## Test configuration

Core runtime parameters live in `src/gatling/resources/simulation.conf` and can be overridden with JVM properties:

```bash
-DbaseUrl=http://localhost
-Dintensity="60 rpm"
-DstagesNumber=2
-DrampDuration="1 minute"
-DstageDuration="5 minutes"
-DtestDuration="15 minutes"
```

Picatinny startup output is controlled by config:

```hocon
picatinny.startup.banner.enabled = true
picatinny.diagnostics.enabled = false
```

Set diagnostics to `true` only when you need extra JVM/runtime details during troubleshooting.

## Starter defaults for optional plugins

If you enable JDBC or AMQP modules, the generated protocol builders start with
conservative defaults for first-run safety:

- JDBC `connectionTimeout`: `10 seconds`
- AMQP `replyTimeout`: `10 seconds`
- AMQP `consumerThreadsCount`: `1`

Tune these values upward in `{{ .NameWord }}.scala` if your infrastructure is
slower or your workload needs higher concurrency.

## Debug

1. Debug test with 1 user, requires proxy on localhost:8888, eg using Fiddler or Wireshark

```
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.Debug
```

2. Run test from IDEA with breakpoints

```
{{ .Package }}.GatlingRunner
```

## Launch test

```
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.MaxPerformance
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.Stability
```

Both load simulations define `val injector = ...` and call `Utility.banner(injector)` so startup banner matches workload profile.

## Help

Picatinny docs: https://github.com/galax-io/gatling-picatinny
Gatling docs: https://gatling.io/docs/gatling/reference/current/core/injection/
