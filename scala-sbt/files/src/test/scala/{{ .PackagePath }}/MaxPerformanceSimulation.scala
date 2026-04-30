package {{ .Package }}

import io.gatling.core.Predef._
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.Performance.httpProtocol
import {{ .Package }}.scenarios.MainScenario

class MaxPerformanceSimulation extends Simulation {
  setUp(
    MainScenario().inject(
      incrementUsersPerSec(intensity / stagesNumber)
        .times(stagesNumber)
        .eachLevelLasting(stageDuration)
        .separatedByRampsLasting(rampDuration)
        .startingFrom(0.0),
    ),
  ).protocols(httpProtocol)
    .maxDuration(testDuration)
}
