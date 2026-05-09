package {{ .Package }}.{{ .NameWord }};

import io.gatling.javaapi.core.Simulation;
import org.galaxio.gatling.javaapi.Utility;
import {{ .Package }}.{{ .NameWord }}.scenarios.HttpScenario;

import static io.gatling.javaapi.core.CoreDsl.atOnceUsers;
import static org.galaxio.gatling.javaapi.SimulationConfig.testDuration;

public class Debug extends Simulation {

    {
        Utility.diagnostics();

        setUp(
                HttpScenario.create()
                        .injectOpen(atOnceUsers(1))
        ).protocols(Performance.httpProtocol)
                .maxDuration(testDuration());
    }
}
