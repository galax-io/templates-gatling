package {{ .Package }}.{{ .NameWord }}.scenarios

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import {{ .Package }}.{{ .NameWord }}.cases.JdbcActions

object JdbcScenario {
  def apply(): ScenarioBuilder = scenario("Jdbc Scenario")
    .exec(JdbcActions.createTable)
}
