package {{ .Package }}.{{ .NameWord }}.scenarios

import io.gatling.javaapi.core.CoreDsl.scenario
import io.gatling.javaapi.core.ScenarioBuilder
import {{ .Package }}.{{ .NameWord }}.cases.JdbcActions

object JdbcScenario {
    fun create(): ScenarioBuilder =
        scenario("Jdbc Scenario")
            .exec(JdbcActions.createTable)
}
