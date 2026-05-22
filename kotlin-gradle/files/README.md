# {{ .Name }}

Gatling Kotlin project with Gradle in Galaxio style.

## Structure

```text
src/gatling/kotlin/{{ .PackagePath }}/{{ .NameWord }}/
  Performance.kt
  Debug.kt
  Stability.kt
  MaxPerformance.kt
  cases/HttpActions.kt
  scenarios/HttpScenario.kt
src/gatling/resources/
  simulation.conf
  gatling.conf
  logback.xml
```

## Run

```bash
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.Debug
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.Stability
./gradlew gatlingRun --simulation {{ .Package }}.{{ .NameWord }}.MaxPerformance
```

## Starter defaults for optional plugins

If you enable JDBC or AMQP modules, the generated `Performance.kt` starts with
conservative defaults for first-run safety:

- JDBC `connectionTimeout`: `10 seconds`
- AMQP `replyTimeout`: `10 seconds`
- AMQP `consumerThreadsCount`: `1`

Tune these values upward in `Performance.kt` if your infrastructure is slower
or your workload needs higher concurrency.
