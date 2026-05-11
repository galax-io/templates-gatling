package {{ .Package }}.{{ .NameWord }}.scenarios

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import {{ .Package }}.{{ .NameWord }}.cases.KafkaActions

object KafkaScenario {
  def apply(): ScenarioBuilder = scenario("Kafka Scenario")
    .exec(KafkaActions.sendMessage)
}
