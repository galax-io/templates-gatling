package {{ .Package }}.{{ .NameWord }}.scenarios;

import io.gatling.javaapi.core.ScenarioBuilder;

import static io.gatling.javaapi.core.CoreDsl.scenario;

import {{ .Package }}.{{ .NameWord }}.cases.HttpActions;

public final class HttpScenario {

    private HttpScenario() {
    }

    public static ScenarioBuilder create() {
        return scenario("Http Scenario")
                .exec(HttpActions.getMainPage);
    }
}
