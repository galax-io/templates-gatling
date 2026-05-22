# {{ .Name }}

Gatling Java project with Maven in Galaxio style.

## Structure

```text
src/test/java/{{ .PackagePath }}/{{ .NameWord }}/
  Performance.java
  Debug.java
  Stability.java
  MaxPerformance.java
  cases/HttpActions.java
  scenarios/HttpScenario.java
src/test/resources/
  simulation.conf
  gatling.conf
  logback.xml
```

## Run

```bash
./mvnw gatling:test -Dgatling.simulationClass={{ .Package }}.{{ .NameWord }}.Debug
./mvnw gatling:test -Dgatling.simulationClass={{ .Package }}.{{ .NameWord }}.Stability
./mvnw gatling:test -Dgatling.simulationClass={{ .Package }}.{{ .NameWord }}.MaxPerformance
```

`Stability` and `MaxPerformance` declare `injectionProfile` and pass it into
`Utility.banner(injectionProfile)`.

## Starter defaults for optional plugins

If you enable JDBC or AMQP modules, the generated `Performance.java` starts
with conservative defaults for first-run safety:

- JDBC `connectionTimeout`: `10 seconds`
- AMQP `replyTimeout`: `10 seconds`
- AMQP `consumerThreadsCount`: `1`

Tune these values upward in `Performance.java` if your infrastructure is slower
or your workload needs higher concurrency.
