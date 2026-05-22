# {{ .Name }}

Gatling Scala project with sbt in Galaxio style.

## Prerequisites

- Java 17 (default; see `JavaVersion` template input to change)
- sbt 1.x (`sbt --version` to check)
- A service running at `baseUrl` (default: `{{ .BaseUrl }}`)

## First run

Point `baseUrl` at a running service, then run the smoke simulation with a single virtual user:

```bash
sbt -batch -DbaseUrl=https://your-service.example.com \
    "Gatling/testOnly {{ .Package }}.{{ .NameWord }}.Debug"
```

A successful run prints a summary table to the console and writes an HTML report to:

```
target/gatling/<simulation-name>-<timestamp>/index.html
```

If the run fails, see [Troubleshooting](#troubleshooting).

## Project structure

```text
src/test/resources/
  simulation.conf     # runtime parameters
  gatling.conf        # Gatling engine settings
  logback.xml         # logging config
src/test/scala/{{ .PackagePath }}/{{ .NameWord }}/
  {{ .NameWord }}.scala          # protocol builders
  Debug.scala         # single-user smoke simulation
  Stability.scala     # constant-rate load simulation
  MaxPerformance.scala  # ramp load simulation
  cases/              # reusable Gatling actions
  scenarios/          # scenario assemblers
```

## Configuration

Runtime parameters live in `src/test/resources/simulation.conf`:

```hocon
baseUrl    = "{{ .BaseUrl }}"
intensity  = "{{ .Intensity }}"
```

Override any parameter at run time with a JVM property:

```bash
sbt -batch -DbaseUrl=https://api.example.com \
    -Dintensity="120 rpm" \
    "Gatling/testOnly {{ .Package }}.{{ .NameWord }}.Stability"
```

Common overrides:

| Property | Default | Description |
|---|---|---|
| `baseUrl` | `{{ .BaseUrl }}` | Target service root URL |
| `intensity` | `{{ .Intensity }}` | Request rate (e.g. `120 rpm`) |
| `stagesNumber` | `{{ .StagesNumber }}` | Number of load stages |
| `rampDuration` | `{{ .RampDuration }}` | Ramp time per stage |
| `stageDuration` | `{{ .StageDuration }}` | Steady-state duration per stage |
| `testDuration` | `{{ .TestDuration }}` | Hard time cap for the simulation |

Picatinny startup output is controlled separately:

```hocon
picatinny.startup.banner.enabled = true
picatinny.diagnostics.enabled    = false
```

Set `diagnostics` to `true` for extra JVM/runtime details during troubleshooting.

## Load simulations

```bash
# Ramp load — incrementally increases VUs across stages
sbt -batch "Gatling/testOnly {{ .Package }}.{{ .NameWord }}.MaxPerformance"

# Constant load — ramps once, then holds
sbt -batch "Gatling/testOnly {{ .Package }}.{{ .NameWord }}.Stability"
```

Both simulations call `Utility.banner(injector)` at start-up so the console banner matches the workload profile.

## Optional plugin defaults

If JDBC or AMQP modules are enabled, the generated protocol builders use conservative defaults:

| Setting | Default |
|---|---|
| JDBC `connectionTimeout` | 10 seconds |
| AMQP `replyTimeout` | 10 seconds |
| AMQP `consumerThreadsCount` | 1 |

Tune these values in the protocol builder file (`{{ .NameWord }}.scala`) if your infrastructure needs more time or higher concurrency.

## IDE debugging (optional)

To run with breakpoints in IntelliJ IDEA, use the `GatlingRunner` entry point:

```
{{ .Package }}.GatlingRunner
```

No proxy is required; the `Debug` simulation targets `baseUrl` directly with one virtual user.

## Troubleshooting

**Connection refused / timeout on first run**
- Verify `baseUrl` in `simulation.conf` points to a running service.
- Run `curl {{ .BaseUrl }}` to confirm reachability.

**`java.lang.UnsupportedClassVersionError`**
- Check your Java version: `java -version`. Gatling requires Java 11 or 17.

**sbt not found**
- Install sbt: https://www.scala-sbt.org/download/

## Links

- Picatinny docs: https://github.com/galax-io/gatling-picatinny
- Gatling injection docs: https://gatling.io/docs/gatling/reference/current/core/injection/
