package {{ .Package }}.{{ .NameWord }}.scenarios

import io.gatling.javaapi.core.CoreDsl.scenario
import io.gatling.javaapi.core.ScenarioBuilder
import {{ .Package }}.{{ .NameWord }}.cases.HttpActions

object HttpScenario {
    fun create(): ScenarioBuilder =
        scenario("Http Scenario")
            .exec(HttpActions.getMainPage)
}
