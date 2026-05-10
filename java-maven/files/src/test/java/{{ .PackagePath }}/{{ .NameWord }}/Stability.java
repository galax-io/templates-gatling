package {{ .Package }}.{{ .NameWord }};

import io.gatling.javaapi.core.OpenInjectionStep;
import io.gatling.javaapi.core.Simulation;
import org.galaxio.gatling.javaapi.SimulationConfig;
import org.galaxio.gatling.javaapi.Utility;
import {{ .Package }}.{{ .NameWord }}.scenarios.HttpScenario;

import static io.gatling.javaapi.core.CoreDsl.constantUsersPerSec;
import static io.gatling.javaapi.core.CoreDsl.rampUsersPerSec;

public class Stability extends Simulation {

    {
        OpenInjectionStep[] injectionProfile = new OpenInjectionStep[]{
                rampUsersPerSec(0.0).to(SimulationConfig.intensity())
                        .during(SimulationConfig.rampDuration()),
                constantUsersPerSec(SimulationConfig.intensity())
                        .during(SimulationConfig.stageDuration())
        };

        Utility.banner(injectionProfile);

        setUp(
                HttpScenario.create()
                        .injectOpen(injectionProfile)
        ).protocols(
                Performance.httpProtocol
        )
                .maxDuration(SimulationConfig.testDuration());
    }
}
