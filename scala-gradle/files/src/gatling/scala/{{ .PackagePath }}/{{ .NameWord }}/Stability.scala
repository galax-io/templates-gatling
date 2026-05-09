package {{ .Package }}.{{ .NameWord }}

import io.gatling.core.Predef._
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.{{ .NameWord }}.scenarios._

class Stability extends Simulation {
  val injector = Seq(
    rampUsersPerSec(0) to intensity during rampDuration,
    constantUsersPerSec(intensity) during stageDuration,
  )

  org.galaxio.gatling.utils.Utility.banner(injector)

  setUp(
    HttpScenario().inject(
      injector,
    ),
  ).protocols(
    httpProtocol,
  ).maxDuration(testDuration)

}
