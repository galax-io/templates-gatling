package {{ .Package }}.scenarios

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import org.galaxio.gatling.config.SimulationConfig._
import {{ .Package }}.cases.HttpCases
import {{ .Package }}.feeders.Feeders

object ClosedPacingScenario {
  def apply(): ScenarioBuilder = new ClosedPacingScenario().scn
}

class ClosedPacingScenario {
  private val pacingDuration = getDurationParam("pacing")

  val scn: ScenarioBuilder = scenario("Closed Pacing Scenario")
    .forever(
      pace(pacingDuration)
        .feed(Feeders.messageId)
        .exec(HttpCases.getMainPage),
    )
}
