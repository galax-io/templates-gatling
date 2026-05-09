# {{ .Name }}

Gatling Java project with Maven in Galaxio style.

## Structure

```text
src/test/java/{{ .PackagePath }}/{{ .NameWord }}/
  Performance.java
  PerformanceSupport.java
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
