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
