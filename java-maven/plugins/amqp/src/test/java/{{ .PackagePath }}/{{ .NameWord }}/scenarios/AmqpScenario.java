package {{ .Package }}.{{ .NameWord }}.scenarios;

import io.gatling.javaapi.core.ScenarioBuilder;
import {{ .Package }}.{{ .NameWord }}.cases.AmqpActions;

import static io.gatling.javaapi.core.CoreDsl.scenario;

public final class AmqpScenario {

    private AmqpScenario() {
    }

    public static ScenarioBuilder create() {
        return scenario("Amqp Scenario")
                .exec(AmqpActions.publishMessage);
    }
}
