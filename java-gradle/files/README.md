# {{ .Name }}

Gatling Java project with Gradle in Galaxio style.

## Structure

```text
src/gatling/java/{{ .PackagePath }}/{{ .NameWord }}/
  Performance.java
  Debug.java
  Stability.java
  MaxPerformance.java
  cases/HttpActions.java
  scenarios/HttpScenario.java
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

If you enable JDBC or AMQP modules, the generated `Performance.java` starts
with conservative defaults for first-run safety:

- JDBC `connectionTimeout`: `10 seconds`
- AMQP `replyTimeout`: `10 seconds`
- AMQP `consumerThreadsCount`: `1`

Tune these values upward in `Performance.java` if your infrastructure is slower
or your workload needs higher concurrency.
