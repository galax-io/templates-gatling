package {{ .Package }}.{{ .NameWord }}.scenarios

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import {{ .Package }}.{{ .NameWord }}.cases.AmqpActions

object AmqpScenario {
  def apply(): ScenarioBuilder = scenario("Amqp Scenario")
    .exec(AmqpActions.publishMessage)
}
