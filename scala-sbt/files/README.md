# Gatling Template Project

Template project for Gatling performance tests

## Project structure

```
src.test.resources - project resources
src.test.scala.{{ .Package }}.{{ .NameWord }}.cases - simple cases
src.test.scala.{{ .Package }}.{{ .NameWord }}.scenarios - common load scenarios assembled from simple cases
src.test.scala.{{ .Package }}.{{ .NameWord }} - common test configs
```

## Test configuration

Core runtime parameters live in `src/test/resources/simulation.conf` and can be overridden with JVM properties:

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

## Debug

1. Debug test with 1 user, requires proxy on localhost:8888, eg using Fiddler or Wireshark

```
"Gatling/testOnly {{ .Package }}.{{ .NameWord }}.Debug"
```

2. Run test from IDEA with breakpoints

```
{{ .Package }}.GatlingRunner
```

## Launch test

```
"Gatling/testOnly {{ .Package }}.{{ .NameWord }}.MaxPerformance" - maximum performance test
"Gatling/testOnly {{ .Package }}.{{ .NameWord }}.Stability" - stability test
```

Both load simulations define `val injector = ...` and call `Utility.banner(injector)` so startup banner matches workload profile.

## Help

Picatinny docs: https://github.com/galax-io/gatling-picatinny
Gatling docs: https://gatling.io/docs/gatling/reference/current/core/injection/
