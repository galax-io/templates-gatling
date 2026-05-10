package {{ .Package }}.{{ .NameWord }}.cases

import io.gatling.core.Predef._
import org.galaxio.gatling.amqp.Predef._
import org.galaxio.gatling.config.SimulationConfig.getStringParam

object AmqpActions {
  val publishMessage = exec(
    amqp("Publish").publish
      .queueExchange(getStringParam("amqpQueue"))
      .textMessage("Hello message")
      .messageId("1")
      .priority(0),
  )
}
