package {{ .Package }}

import io.gatling.core.Predef._
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.Performance.httpProtocol
import {{ .Package }}.scenarios.MainScenario

class StabilitySimulation extends Simulation {
  setUp(
    MainScenario().inject(
      rampUsersPerSec(0).to(intensity).during(rampDuration),
      constantUsersPerSec(intensity).during(stageDuration),
    ),
  ).protocols(httpProtocol)
    .maxDuration(testDuration)
}
