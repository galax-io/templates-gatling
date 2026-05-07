package {{ .Package }}.{{ .NameWord }}

import io.gatling.core.Predef._
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.{{ .NameWord }}.scenarios._

class Stability extends Simulation {

  setUp(
    HttpScenario().inject(
      // разгон
      rampUsersPerSec(0) to intensity.toInt during rampDuration,
      // полка
      constantUsersPerSec(intensity.toInt) during stageDuration,
    ),
  ).protocols(
    httpProtocol,
    // длительность теста = разгон + полка
  ).maxDuration(testDuration)

}
