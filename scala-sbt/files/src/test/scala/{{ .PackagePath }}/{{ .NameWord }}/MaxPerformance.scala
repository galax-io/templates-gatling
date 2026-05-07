package {{ .Package }}.{{ .NameWord }}

import io.gatling.core.Predef._
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.{{ .NameWord }}.scenarios._

class MaxPerformance extends Simulation {
  val injector = incrementUsersPerSec((intensity / stagesNumber).toInt)
    .times(stagesNumber)
    .eachLevelLasting(stageDuration)
    .separatedByRampsLasting(rampDuration)
    .startingFrom(0)

  org.galaxio.gatling.utils.Utility.banner(injector)

  setUp(
    HttpScenario().inject(
      injector,
    ),
  ).protocols(
    httpProtocol,
  ).maxDuration(testDuration)

}
