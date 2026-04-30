package {{ .Package }}

import io.gatling.core.Predef._
import scala.concurrent.duration.DurationInt
import {{ .Package }}.Performance.httpProtocol
import {{ .Package }}.scenarios.MainScenario

class DebugSimulation extends Simulation {
  setUp(
    MainScenario().inject(atOnceUsers(1)),
  ).protocols(httpProtocol)
    .maxDuration(1.minute)
}
