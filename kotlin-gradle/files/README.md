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
