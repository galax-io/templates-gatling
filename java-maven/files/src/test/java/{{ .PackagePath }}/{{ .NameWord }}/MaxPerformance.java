package {{ .Package }}.{{ .NameWord }};

import io.gatling.javaapi.core.OpenInjectionStep;
import io.gatling.javaapi.core.Simulation;
import org.galaxio.gatling.javaapi.SimulationConfig;
import org.galaxio.gatling.javaapi.Utility;
import {{ .Package }}.{{ .NameWord }}.scenarios.HttpScenario;

import static io.gatling.javaapi.core.CoreDsl.incrementUsersPerSec;

public class MaxPerformance extends Simulation {

    {
        OpenInjectionStep[] injectionProfile = new OpenInjectionStep[]{
                incrementUsersPerSec(SimulationConfig.intensity() / SimulationConfig.stagesNumber())
                        .times(SimulationConfig.stagesNumber())
                        .eachLevelLasting(SimulationConfig.stageDuration())
                        .separatedByRampsLasting(SimulationConfig.rampDuration())
                        .startingFrom(0.0)
        };

        Utility.banner(injectionProfile);

        setUp(
                HttpScenario.create()
                        .injectOpen(injectionProfile)
        ).protocols(Performance.httpProtocol)
                .maxDuration(SimulationConfig.testDuration());
    }
}
