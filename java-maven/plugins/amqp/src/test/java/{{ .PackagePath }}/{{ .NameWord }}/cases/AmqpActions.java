package {{ .Package }}.{{ .NameWord }}.cases;

import io.gatling.javaapi.core.ChainBuilder;
import org.galaxio.gatling.amqp.javaapi.AmqpDsl;

import static io.gatling.javaapi.core.CoreDsl.exec;
import static org.galaxio.gatling.javaapi.SimulationConfig.getStringParam;

public final class AmqpActions {

    public static final ChainBuilder publishMessage =
            exec(AmqpDsl.amqp("Publish")
                    .publish()
                    .queueExchange(getStringParam("amqpQueue"))
                    .textMessage("Hello message")
                    .messageId("1")
                    .priority(0));

    private AmqpActions() {
    }
}
