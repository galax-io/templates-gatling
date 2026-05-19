package {{ .Package }}.{{ .NameWord }}.cases

import io.gatling.core.Predef._
import org.galaxio.gatling.kafka.Predef._
import org.galaxio.gatling.config.SimulationConfig.getStringParam

object KafkaActions {
  val sendMessage = exec(
    kafka("Kafka publish")
      .send[String, String]("myMessage", "Hello!"),
  )
}
