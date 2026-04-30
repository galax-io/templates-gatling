package {{ .Package }}

import io.gatling.core.Predef._
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.Performance.httpProtocol
import {{ .Package }}.scenarios.ClosedPacingScenario

class ClosedPacingSimulation extends Simulation {
  setUp(
    ClosedPacingScenario().inject(
      rampConcurrentUsers(0).to(intensity.toInt).during(rampDuration),
      constantConcurrentUsers(intensity.toInt).during(stageDuration),
    ),
  ).protocols(httpProtocol)
    .maxDuration(testDuration)
}
