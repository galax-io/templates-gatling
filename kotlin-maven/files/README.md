# {{ .Name }}

Gatling Kotlin project with Maven in Galaxio style.

## Structure

```text
src/test/kotlin/{{ .PackagePath }}/{{ .NameWord }}/
  Performance.kt
  Debug.kt
  Stability.kt
  MaxPerformance.kt
  cases/HttpActions.kt
  scenarios/HttpScenario.kt
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
