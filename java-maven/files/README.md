# {{ .Name }}

Gatling Java project with Maven in Galaxio style.

## Prerequisites

- Java 17 (default; see `JavaVersion` template input to change)
- The included `./mvnw` wrapper downloads Maven automatically on first use.
- A service running at `baseUrl` (default: `{{ .BaseUrl }}`)

## First run

Point `baseUrl` at a running service, then run the smoke simulation with a single virtual user:

```bash
chmod +x ./mvnw
./mvnw gatling:test -Dgatling.simulationClass={{ .Package }}.{{ .NameWord }}.Debug -DbaseUrl=https://your-service.example.com
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
src/test/java/{{ .PackagePath }}/{{ .NameWord }}/
  Performance.java    # protocol builders
  Debug.java          # single-user smoke simulation
  Stability.java      # constant-rate load simulation
  MaxPerformance.java # ramp load simulation
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
./mvnw gatling:test \
  -Dgatling.simulationClass={{ .Package }}.{{ .NameWord }}.Stability \
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

## Load simulations

```bash
# Ramp load — incrementally increases VUs across stages
./mvnw gatling:test -Dgatling.simulationClass={{ .Package }}.{{ .NameWord }}.MaxPerformance

# Constant load — ramps once, then holds
./mvnw gatling:test -Dgatling.simulationClass={{ .Package }}.{{ .NameWord }}.Stability
```

`Stability` and `MaxPerformance` call `Utility.banner(injectionProfile)` at start-up so the console banner matches the workload profile.

## Optional plugin defaults

If JDBC or AMQP modules are enabled, the generated `Performance.java` uses conservative defaults:

| Setting | Default |
|---|---|
| JDBC `connectionTimeout` | 10 seconds |
| AMQP `replyTimeout` | 10 seconds |
| AMQP `consumerThreadsCount` | 1 |

Tune these values in `Performance.java` if your infrastructure needs more time or higher concurrency.

## Troubleshooting

**Connection refused / timeout on first run**
- Verify `baseUrl` in `simulation.conf` points to a running service.
- Run `curl {{ .BaseUrl }}` to confirm reachability.

**`java.lang.UnsupportedClassVersionError`**
- Check your Java version: `java -version`. Gatling requires Java 11 or 17.

**`./mvnw: Permission denied`**
- Make the wrapper executable: `chmod +x ./mvnw`

## Links

- Picatinny docs: https://github.com/galax-io/gatling-picatinny
- Gatling injection docs: https://gatling.io/docs/gatling/reference/current/core/injection/
