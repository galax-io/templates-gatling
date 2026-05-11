package {{ .Package }}.{{ .NameWord }}.scenarios;

import io.gatling.javaapi.core.ScenarioBuilder;
import {{ .Package }}.{{ .NameWord }}.cases.KafkaActions;

import static io.gatling.javaapi.core.CoreDsl.scenario;

public final class KafkaScenario {

    private KafkaScenario() {
    }

    public static ScenarioBuilder create() {
        return scenario("Kafka Scenario")
                .exec(KafkaActions.sendMessage);
    }
}
