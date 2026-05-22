# {{ .Name }}

Gatling Scala project with Gradle in Galaxio style.

## Prerequisites

- Java 11 or 17 (LTS)
- The included `./gradlew` wrapper downloads Gradle automatically on first use.

## First run

Run the smoke simulation with a single virtual user against the default `baseUrl`:

```bash
chmod +x ./gradlew
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.Debug
```

A successful run prints a summary table to the console and writes an HTML report to:

```
build/reports/gatling/<simulation-name>-<timestamp>/index.html
```

If the run fails, see [Troubleshooting](#troubleshooting).

## Project structure

```text
src/gatling/resources/
  simulation.conf     # runtime parameters
  gatling.conf        # Gatling engine settings
  logback.xml         # logging config
src/gatling/scala/{{ .PackagePath }}/{{ .NameWord }}/
  {{ .NameWord }}.scala          # protocol builders
  Debug.scala         # single-user smoke simulation
  Stability.scala     # constant-rate load simulation
  MaxPerformance.scala  # ramp load simulation
  cases/              # reusable Gatling actions
  scenarios/          # scenario assemblers
```

## Configuration

Runtime parameters live in `src/gatling/resources/simulation.conf`:

```hocon
baseUrl    = "{{ .BaseUrl }}"
intensity  = "{{ .Intensity }}"
```

Override any parameter at run time with a JVM property:

```bash
./gradlew gatlingRun \
  --simulation {{ .Package }}.{{ .NameWord }}.Stability \
  -DbaseUrl=https://api.example.com \
  -Dintensity="120 rpm"
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
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.MaxPerformance

# Constant load — ramps once, then holds
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.Stability
```

Both simulations call `Utility.banner(injector)` at start-up so the console banner matches the workload profile.

## Optional plugin defaults

If JDBC or AMQP modules are enabled, the generated protocol builders use conservative defaults:

| Setting | Default | Where to change |
|---|---|---|
| JDBC `connectionTimeout` | 10 seconds | `{{ .NameWord }}.scala` |
| AMQP `replyTimeout` | 10 seconds | `{{ .NameWord }}.scala` |
| AMQP `consumerThreadsCount` | 1 | `{{ .NameWord }}.scala` |

Increase these values if your infrastructure needs more time or higher concurrency.

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

**`./gradlew: Permission denied`**
- Make the wrapper executable: `chmod +x ./gradlew`

## Links

- Picatinny docs: https://github.com/galax-io/gatling-picatinny
- Gatling injection docs: https://gatling.io/docs/gatling/reference/current/core/injection/
