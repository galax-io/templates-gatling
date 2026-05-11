package {{ .Package }}.{{ .NameWord }}.scenarios

import io.gatling.javaapi.core.CoreDsl.scenario
import io.gatling.javaapi.core.ScenarioBuilder
import {{ .Package }}.{{ .NameWord }}.cases.AmqpActions

object AmqpScenario {
    fun create(): ScenarioBuilder =
        scenario("Amqp Scenario")
            .exec(AmqpActions.publishMessage)
}
