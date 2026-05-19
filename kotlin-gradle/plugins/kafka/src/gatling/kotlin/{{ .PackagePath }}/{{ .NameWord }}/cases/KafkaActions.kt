package {{ .Package }}.{{ .NameWord }}.cases

import io.gatling.javaapi.core.ChainBuilder
import io.gatling.javaapi.core.CoreDsl.exec
import org.galaxio.gatling.kafka.javaapi.KafkaDsl
import org.galaxio.gatling.javaapi.SimulationConfig.getStringParam

object KafkaActions {
    val sendMessage: ChainBuilder = exec(
        KafkaDsl.kafka("Kafka publish").send("myMessage", "Hello!")
    )
}
