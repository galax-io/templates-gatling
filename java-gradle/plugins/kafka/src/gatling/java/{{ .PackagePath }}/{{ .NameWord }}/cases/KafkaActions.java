package {{ .Package }}.{{ .NameWord }}.cases;

import io.gatling.javaapi.core.ChainBuilder;
import org.galaxio.gatling.kafka.javaapi.KafkaDsl;

import static io.gatling.javaapi.core.CoreDsl.exec;
import static org.galaxio.gatling.javaapi.SimulationConfig.getStringParam;

public final class KafkaActions {

    public static final ChainBuilder sendMessage =
            exec(KafkaDsl.kafka("Kafka publish").send("myMessage", "Hello!"));

    private KafkaActions() {
    }
}
