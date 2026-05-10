package {{ .Package }}.{{ .NameWord }}.scenarios

import io.gatling.javaapi.core.CoreDsl.scenario
import io.gatling.javaapi.core.ScenarioBuilder
import {{ .Package }}.{{ .NameWord }}.cases.KafkaActions

object KafkaScenario {
    fun create(): ScenarioBuilder =
        scenario("Kafka Scenario")
            .exec(KafkaActions.sendMessage)
}
