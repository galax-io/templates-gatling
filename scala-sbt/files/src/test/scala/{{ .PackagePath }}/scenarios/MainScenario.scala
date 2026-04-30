package {{ .Package }}.scenarios

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import {{ .Package }}.cases.HttpCases
import {{ .Package }}.feeders.Feeders

object MainScenario {
  def apply(): ScenarioBuilder = new MainScenario().scn
}

class MainScenario {
  val scn: ScenarioBuilder = scenario("Main Scenario")
    .feed(Feeders.messageId)
    .exec(HttpCases.getMainPage)
}
