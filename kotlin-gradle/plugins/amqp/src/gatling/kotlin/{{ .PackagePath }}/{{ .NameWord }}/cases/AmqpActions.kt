package {{ .Package }}.{{ .NameWord }}.cases

import io.gatling.javaapi.core.ChainBuilder
import io.gatling.javaapi.core.CoreDsl.exec
import org.galaxio.gatling.amqp.javaapi.AmqpDsl
import org.galaxio.gatling.javaapi.SimulationConfig.getStringParam

object AmqpActions {
    val publishMessage: ChainBuilder = exec(
        AmqpDsl.amqp("Publish")
            .publish()
            .queueExchange(getStringParam("amqpQueue"))
            .textMessage("Hello message")
            .messageId("1")
            .priority(0)
    )
}
