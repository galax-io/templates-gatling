package {{ .Package }}.{{ .NameWord }}.scenarios;

import io.gatling.javaapi.core.ScenarioBuilder;
import {{ .Package }}.{{ .NameWord }}.cases.JdbcActions;

import static io.gatling.javaapi.core.CoreDsl.scenario;

public final class JdbcScenario {

    private JdbcScenario() {
    }

    public static ScenarioBuilder create() {
        return scenario("Jdbc Scenario")
                .exec(JdbcActions.createTable);
    }
}
